#!/usr/bin/env bash
set -euo pipefail

usage() {
	echo "usage: $0 <hostname> <ssh-user@host>" >&2
	exit 2
}

[[ $# -eq 2 ]] || usage

hostname=$1
target=$2
repo_root=$(git rev-parse --show-toplevel)
host_dir="$repo_root/hosts/$hostname"
collateral="/tmp/nix-config-provisioning/$hostname"
age_key=${SOPS_AGE_KEY_FILE:-$HOME/.age/parthiv.age}

[[ $hostname =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
	echo "invalid hostname: $hostname" >&2
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

install -d -m 700 "$collateral"
trap 'rm -rf "$collateral"' ERR INT TERM
install -d -m 755 "$collateral/persist/system/etc/ssh"
install -d -m 700 "$collateral/persist/home/parthiv/.age"

required_host_keys=(ssh_host_ed25519_key ssh_host_ed25519_key.pub)
optional_host_keys=(ssh_host_rsa_key ssh_host_rsa_key.pub)

for key in "${required_host_keys[@]}"; do
	# shellcheck disable=SC2029
	ssh "$target" sudo cat "/etc/ssh/$key" \
		>"$collateral/persist/system/etc/ssh/$key"
done

for key in "${optional_host_keys[@]}"; do
	if ssh "$target" sudo test -f "/etc/ssh/$key"; then
		# shellcheck disable=SC2029
		ssh "$target" sudo cat "/etc/ssh/$key" \
			>"$collateral/persist/system/etc/ssh/$key"
	fi
done

install -m 600 "$age_key" "$collateral/persist/home/parthiv/.age/parthiv.age"
chmod 600 \
	"$collateral/persist/system/etc/ssh/ssh_host_ed25519_key"
chmod 644 \
	"$collateral/persist/system/etc/ssh/ssh_host_ed25519_key.pub"
[[ ! -f $collateral/persist/system/etc/ssh/ssh_host_rsa_key ]] ||
	chmod 600 "$collateral/persist/system/etc/ssh/ssh_host_rsa_key"
[[ ! -f $collateral/persist/system/etc/ssh/ssh_host_rsa_key.pub ]] ||
	chmod 644 "$collateral/persist/system/etc/ssh/ssh_host_rsa_key.pub"

recipient=$(ssh-keygen -y -f \
	"$collateral/persist/system/etc/ssh/ssh_host_ed25519_key" |
	nix shell nixpkgs#ssh-to-age -c ssh-to-age)
fingerprint=$(ssh-keygen -lf \
	"$collateral/persist/system/etc/ssh/ssh_host_ed25519_key.pub" | cut -d ' ' -f 2)

install -d "$host_dir"
if [[ ! -e $host_dir/hardware-configuration.nix ]]; then
	printf '%s\n' '# Replaced by scripts/provisioning/install-host.sh.' '{ }' \
		>"$host_dir/hardware-configuration.nix"
fi
git add --intent-to-add -- "$host_dir/hardware-configuration.nix"

cat <<EOF
Prepared private provisioning collateral in:
  $collateral

SSH host age recipient:
  $recipient

SSH host fingerprint:
  $fingerprint

Next steps:
1. Create hosts/$hostname/default.nix and hosts/$hostname/disks.nix.
2. Add $hostname to constants.nix.
3. Create $hostname.yaml in nix-config-secrets, encrypted to the recipient above.
4. Run: nix flake update nix-config-secrets
5. Validate the host configuration and disk device.
6. Run: scripts/provisioning/install-host.sh $hostname $target

The collateral contains private keys. Securely remove it after verification.
EOF
