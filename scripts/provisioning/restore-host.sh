#!/usr/bin/env bash
set -euo pipefail

usage() {
	echo "usage: $0 <hostname> <root@direct-ssh-host> [snapshot]" >&2
	exit 2
}

[[ $# -ge 2 && $# -le 3 ]] || usage

hostname=$1
target=$2
snapshot=${3:-latest}
repo_root=$(git rev-parse --show-toplevel)

[[ $hostname =~ ^[a-z0-9][a-z0-9-]*$ ]] || {
	echo "invalid hostname: $hostname" >&2
	exit 1
}
[[ $target == root@* ]] || {
	echo "restore target must use root: root@<direct-ssh-host>" >&2
	exit 1
}

backup_services=$(nix eval --no-write-lock-file --raw \
	--apply 'xs: builtins.concatStringsSep " " xs' \
	"$repo_root#nixosConfigurations.$hostname.config.custom.features.selfhosted.backupServices")

ssh "$target" 'test -s /run/secrets/restic/password && test -s /run/secrets/restic/repository'
ssh "$target" 'findmnt -rn /persist >/dev/null'

cat <<EOF
WARNING: this overwrites /persist on $target from Restic snapshot $snapshot.

Use a direct provider SSH address, not Tailscale. The restore stops tailscaled
so its persisted state can be restored consistently. These application
services will also be stopped:
  $backup_services

The host reboots immediately after a successful verified restore.
Press Enter to continue or Ctrl-C to abort.
EOF
read -r

ssh "$target" bash -s -- "$hostname" "$snapshot" "$backup_services" <<'REMOTE'
set -euo pipefail

hostname=$1
snapshot=$2
read -r -a backup_services <<< "$3"
restore_services=(
  caddy.service
  harmonia.service
  buildbot-master.service
  buildbot-worker.service
  postgresql.service
)
stopped_services=()

restart_services() {
  for service in "${stopped_services[@]}"; do
    systemctl start "$service" || true
  done
}
trap restart_services ERR

for service in restic-backups-main.timer restic-backups-main.service \
  "${backup_services[@]}" "${restore_services[@]}" tailscaled.service; do
  if systemctl is-active --quiet "$service"; then
    systemctl stop "$service"
    stopped_services+=("$service")
  fi
done

export RESTIC_PASSWORD_FILE=/run/secrets/restic/password
export RESTIC_REPOSITORY_FILE=/run/secrets/restic/repository

restic restore "$snapshot:/persist.backup" \
  --host "$hostname" \
  --target /persist \
  --overwrite always \
  --verify

sync
trap - ERR
systemctl reboot
REMOTE

cat <<EOF
Restore completed and reboot was requested.

The restored Tailscale state may return the host to its previous node identity
and IP. Check the Tailscale admin console and then run:
  tailscale status
  tailscale ping $hostname

After reconnecting, reapply the current configuration:
  nixos-rebuild switch --flake .#$hostname \\
    --target-host root@$hostname --build-host localhost
EOF
