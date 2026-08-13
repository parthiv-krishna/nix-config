# NixOS Provisioning And Recovery

These scripts provision a Linux host over SSH using [`nixos-anywhere`](https://github.com/nix-community/nixos-anywhere), or recover an existing host from its Restic backup.

The target must support kexec and have ssh keys setup for root access.

## New Host

The provisioning workflow preserves the initial SSH host identity so system SOPS can decrypt during first activation. It also installs the personal age identity used by Home Manager.

Enter the development shell:

```bash
nix develop
```

### Prepare The Host

```bash
scripts/provisioning/prepare-host.sh <hostname> root@<host>
```

This stages the remote SSH host keys and local `~/.age/parthiv.age` in the mode-`0700` `/tmp/nix-config-provisioning/<hostname>/` directory, prints the age recipient derived from the SSH host key, and creates a placeholder `hardware-configuration.nix`.

Be careful with the contents of `/tmp/nix-config-provisioning` as it contains private keys.

### Configure The Host

1. Add the host to `constants.nix`.
2. Create `hosts/<hostname>/default.nix` and `hosts/<hostname>/disks.nix`.
3. Create `<hostname>.yaml` in `nix-config-secrets` and encrypt it to the age recipient printed by `prepare-host.sh`. It helps to create the Tailscale auth key with the appropriate ACL tags pre-assigned to avoid manual tagging.
4. Commit and push the encrypted secrets repository.
5. Run `nix flake update nix-config-secrets` in this repository.
6. Evaluate the host and carefully inspect its Disko configuration and target devices.

### Install The Host

```bash
scripts/provisioning/install-host.sh <hostname> <ssh-user@host>
```

This runs `nixos-anywhere`, generates the final `hardware-configuration.nix` from the kexec installer, copies the protected collateral into the new filesystems, and installs `.#<hostname>`. The devices specified by `disks.nix` are destroyed.

After reboot, approve the new node in the Tailscale admin console and add the necessary ACL tags.

Verify access and services:

```bash
tailscale ping <hostname>
ssh parthiv@<hostname> 'systemctl status --state=failed'
```

Once system/home sops, ssh, persistence, disks, and host services seem to work, delete `/tmp/nix-config-provisioning/<hostname>/`.

## Backup Recovery

Recovery requires restoring the original ssh host key from restic to decrypt secrets.

### Prepare Recovery

On a trusted machine, decrypt the host's `restic/repository` and `restic/password` values into temp files. Point the recovery command at those files:

```bash
export TARGET_HOSTNAME=<hostname>
mkdir -p /tmp/nix-config-provisioning/$TARGET_HOSTNAME
export RESTIC_REPOSITORY_FILE=/tmp/nix-config-provisioning/$TARGET_HOSTNAME/repository.txt
export RESTIC_PASSWORD_FILE=./tmp/nix-config-provisioning/$TARGET_HOSTNAME/password.txt
# from `nix-config-secrets`
(umask 0177 && sops decrypt $TARGET_HOSTNAME.yaml --extract '["restic"]["repository"]' > $RESTIC_REPOSITORY_FILE)
(umask 0177 && sops decrypt $TARGET_HOSTNAME.yaml --extract '["restic"]["password"]' > $RESTIC_PASSWORD_FILE)
# from `nix-config`
scripts/provisioning/prepare-recovery.sh <hostname> [snapshot]
```

`snapshot` is optional as it will default to the latest for that host. `prepare-recovery.sh` lists matching snapshots. Then it restores `/persist.backup/system/etc/ssh` (for sops-nix decryption), stages the recovered host identity and local `~/.age/parthiv.age`, and prints the recovered age recipient. Confirm that the recipient is the expected one for `<hostname>.yaml`.

### Reinstall The Host

```bash
scripts/provisioning/install-host.sh <hostname> <ssh-user@replacement-host>
```

After reboot, approve and tag the temporary Tailscale node.

### Restore Persisted State

Restore the complete persisted tree over direct SSH. Don't use Tailscale since this script stops `tailscaled` to restore its state.

```bash
scripts/provisioning/restore-host.sh \
  <hostname> root@<replacement-public-address> [snapshot]
```

Once again, `snapshot` is optional and it defaults to the latest on that host. This stops the backup services and Tailscale, then restores the state of `/persist`, and finally reboots the system.

Hopefully, there is no need to update the DNS IP addresses since we restore the old Tailscale state. Check the admin console. Either way, we should be able to connect over Tailscale now (e.g. MagnicDNS) and use it to update to the latest system version.

```bash
tailscale ping <hostname>
nixos-rebuild switch --flake .#<hostname> \
  --target-host root@<hostname> --build-host localhost
```

Check system/home manager sops, ssh host fingerprints, persistence mounts, restic, databases, and all host services. Then delete `/tmp/nix-config-provisioning/<hostname>/` and the temporary Restic credential files.
