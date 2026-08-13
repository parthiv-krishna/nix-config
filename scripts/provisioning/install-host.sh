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
identity=${NIXOS_ANYWHERE_IDENTITY:-$HOME/.ssh/id_ed25519}

[[ $hostname =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
	echo "invalid hostname: $hostname" >&2
	exit 1
}
[[ -f $host_dir/default.nix ]] || {
	echo "missing host configuration: $host_dir/default.nix" >&2
	exit 1
}
[[ -f $host_dir/disks.nix ]] || {
	echo "missing Disko configuration: $host_dir/disks.nix" >&2
	exit 1
}
[[ -s $collateral/persist/system/etc/ssh/ssh_host_ed25519_key ]] || {
	echo "missing provisioning collateral; run scripts/provisioning/prepare-host.sh first" >&2
	exit 1
}
[[ -s $collateral/persist/home/parthiv/.age/parthiv.age ]] || {
	echo "missing personal age key in provisioning collateral" >&2
	exit 1
}
[[ -f $identity ]] || {
	echo "SSH identity not found: $identity" >&2
	exit 1
}

git add --intent-to-add -- "$host_dir"

cat <<EOF
WARNING: this will destroy the disks configured by:
  hosts/$hostname/disks.nix

Target: $target
Press Enter to continue or Ctrl-C to abort.
EOF
read -r

nix run github:nix-community/nixos-anywhere -- \
	--flake "$repo_root#$hostname" \
	--target-host "$target" \
	-i "$identity" \
	--extra-files "$collateral" \
	--chown persist/home/parthiv 1000:100 \
	--generate-hardware-config nixos-generate-config \
	"$host_dir/hardware-configuration.nix" \
	--build-on local

cat <<EOF
Installation completed.

1. Approve the new Tailscale node and assign its required ACL tags, unless the
   auth key had the tags pre-assigned.
2. Confirm access with: tailscale ping $hostname
3. Reapply if needed with:
     nixos-rebuild switch --flake .#$hostname \\
       --target-host root@$hostname --build-host localhost
4. Verify SOPS, Home Manager, SSH, disks, and host services.
5. After verification, securely remove:
     rm -rf $collateral
EOF
