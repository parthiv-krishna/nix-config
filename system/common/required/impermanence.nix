# impermanence-related configuration

{
  lib,
  ...
}:

{
  # startup script from https://github.com/nix-community/impermanence
  # 1. backup current state of root
  # 2. clear out backups older than 30d
  # 3. make a new empty root
  boot.initrd.postDeviceCommands = lib.mkAfter ''
    mkdir /btrfs_tmp
    mount /dev/root_vg/root /btrfs_tmp
    if [[ -e /btrfs_tmp/root ]]; then
        mkdir -p /btrfs_tmp/old_roots
        timestamp=$(date --date="@$(stat -c %Y /btrfs_tmp/root)" "+%Y-%m-%-d_%H:%M:%S")
        mv /btrfs_tmp/root "/btrfs_tmp/old_roots/$timestamp"
    fi

    delete_subvolume_recursively() {
        IFS=$'\n'
        for i in $(btrfs subvolume list -o "$1" | cut -f 9- -d ' '); do
            delete_subvolume_recursively "/btrfs_tmp/$i"
        done
        btrfs subvolume delete "$1"
    }

    for i in $(find /btrfs_tmp/old_roots/ -maxdepth 1 -mtime +30); do
        delete_subvolume_recursively "$i"
    done

    btrfs subvolume create /btrfs_tmp/root
    umount /btrfs_tmp
  '';

  # make sure /persist is available during boot
  fileSystems."/persist".neededForBoot = lib.mkForce true;

  # bare minimum system needs when persisting, other modules should add their own
  environment.persistence."/persist/system" = {
    hideMounts = true;
    directories = [
      "/var/lib/nixos"
      "/var/lib/systemd/coredump"
      "/var/log"
    ];
    files = [
      "/etc/machine-id"
    ];
  };

  users.mutableUsers = false;

  /*
    systemd.tmpfiles.rules = [
      "d /persist/home/ 1777 root root -" # /persist/home created, owned by root
      "d /persist/home/parthiv 0770 parthiv users -" # /persist/home/parthiv created, owned by parthiv
    ];
    programs.fuse.userAllowOther = true;
  */

}
