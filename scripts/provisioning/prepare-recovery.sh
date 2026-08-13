#!/usr/bin/env bash
set -euo pipefail

usage() {
	cat >&2 <<EOF
usage: RESTIC_REPOSITORY_FILE=<path> RESTIC_PASSWORD_FILE=<path> \
  $0 <hostname> [snapshot]
EOF
	exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage

hostname=$1
snapshot=${2:-latest}
collateral="/tmp/nix-config-provisioning/$hostname"
restore_dir="$collateral/restic-identity"
age_key=${SOPS_AGE_KEY_FILE:-$HOME/.age/parthiv.age}

[[ $hostname =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
	echo "invalid hostname: $hostname" >&2
	exit 1
}
[[ -f ${RESTIC_REPOSITORY_FILE:-} ]] || {
	echo "RESTIC_REPOSITORY_FILE must name a readable file" >&2
	exit 1
}
[[ -f ${RESTIC_PASSWORD_FILE:-} ]] || {
	echo "RESTIC_PASSWORD_FILE must name a readable file" >&2
	exit 1
}
[[ -f $age_key ]] || {
	echo "personal age key not found: $age_key" >&2
	exit 1
}
[[ ! -e $collateral ]] || {
	echo "provisioning collateral already exists: $collateral" >&2
	echo "remove it after confirming it is no longer needed, then retry" >&2
	exit 1
}

install -d -m 700 "$restore_dir"
trap 'rm -rf "$collateral"' ERR INT TERM

echo "Available snapshots for $hostname:"
nix shell nixpkgs#restic -c restic snapshots --host "$hostname"

echo "Restoring the persisted SSH identity from snapshot $snapshot..."
nix shell nixpkgs#restic -c restic restore \
	"$snapshot:/persist.backup/system/etc/ssh" \
	--host "$hostname" \
	--target "$restore_dir" \
	--verify

[[ -s $restore_dir/ssh_host_ed25519_key &&
	-s $restore_dir/ssh_host_ed25519_key.pub ]] || {
	echo "restored snapshot does not contain the persisted Ed25519 host key" >&2
	exit 1
}

host_key_dir="$collateral/persist/system/etc/ssh"
install -d -m 755 "$host_key_dir"
for key in ssh_host_ed25519_key ssh_host_rsa_key; do
	[[ ! -f $restore_dir/$key ]] ||
		install -m 600 "$restore_dir/$key" "$host_key_dir/$key"
done
for key in ssh_host_ed25519_key.pub ssh_host_rsa_key.pub; do
	[[ ! -f $restore_dir/$key ]] ||
		install -m 644 "$restore_dir/$key" "$host_key_dir/$key"
done

install -d -m 700 "$collateral/persist/home/parthiv/.age"
install -m 600 "$age_key" "$collateral/persist/home/parthiv/.age/parthiv.age"
rm -rf "$restore_dir"

recipient=$(ssh-keygen -y -f \
	"$host_key_dir/ssh_host_ed25519_key" |
	nix shell nixpkgs#ssh-to-age -c ssh-to-age)
fingerprint=$(ssh-keygen -lf \
	"$host_key_dir/ssh_host_ed25519_key.pub" | cut -d ' ' -f 2)

cat <<EOF
Prepared recovery collateral in:
  $collateral

Recovered SSH host age recipient:
  $recipient

Recovered SSH host fingerprint:
  $fingerprint

Confirm that the recipient matches the recipient for $hostname.yaml. Then:
1. Confirm hosts/$hostname contains the intended configuration and disk layout.
2. Run scripts/provisioning/install-host.sh $hostname <ssh-user@replacement-host>.
3. Approve and tag the replacement Tailscale node if necessary.
4. Using direct provider SSH, run:
     scripts/provisioning/restore-host.sh $hostname root@<replacement-host>

The collateral contains private keys. Securely remove it after verification.
EOF
