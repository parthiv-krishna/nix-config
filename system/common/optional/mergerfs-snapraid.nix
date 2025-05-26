{
  dataDevices ? throw "Set this to a list of data devices",
  parityDevices ? throw "Set this to a list of parity devices",
  lib,
  pkgs,
  ...
}:

{
  # Add necessary packages
  environment.systemPackages = with pkgs; [
    mergerfs
    openseachest
    smartmontools
    snapraid
  ];

  # MergerFS configuration
  fileSystems."/persist" = {
    device = lib.strings.concatStringsSep ":" (
      lib.lists.imap0 (i: _disk: "/hdd/data${toString i}") dataDevices
    );
    fsType = "fuse.mergerfs";
    options = [
      "defaults"
      "allow_other"
      "cache.files=partial"
      "category.create=mfs"
      "moveonenospc=true"
      "dropcacheonclose=true"
      "minfreespace=100G"
      "fsname=mergerfs"
    ];
  };

  boot =
    let
      modules = [
        "dm-mod"
        "dm-cache"
        "dm-cache-smq"
        "dm-cache-mq"
      ];
    in
    {
      initrd.kernelModules = modules;
      kernelModules = modules;
    };

  # SnapRAID configuration
  services.snapraid = {
    enable = true;
    contentFiles = lib.lists.imap0 (
      i: _disk: "/hdd/data${toString i}/snapraid${toString i}.content"
    ) dataDevices;
    parityFiles = lib.lists.imap0 (
      i: _disk: "/hdd/parity${toString i}/snapraid${toString i}.parity"
    ) parityDevices;
    dataDisks = builtins.listToAttrs (
      lib.lists.imap0 (i: _disk: {
        name = "disk${toString i}";
        value = "/hdd/data${toString i}";
      }) dataDevices
    );
    exclude = [
      "/tmp/"
      "/lost+found/"
    ];
  };

  # spin down disks after the specified times
  systemd.services."seachest-epc" =
    let
      devices = dataDevices ++ parityDevices;
      # times in ms
      idleATimer = 100; # full rpm
      idleBTimer = 120000; # park heads
      idleCTimer = 600000; # reduce rpm
      standbyZTimer = 900000; # spin down
    in
    {
      description = "Configure Seagate Exos EPC spindown timers";
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${builtins.concatStringsSep "\n" (
          map (dev: ''
              ${pkgs.openseachest}/bin/openSeaChest_PowerControl -d ${dev} \
                --idle_a ${toString idleATimer} \
                --idle_b ${toString idleBTimer} \
                --idle_c ${toString idleCTimer} \
                --standby_z ${toString standbyZTimer}

            echo "Set ${dev} to \
            idle_a=${toString idleATimer}ms, \
            idle_b=${toString idleBTimer}ms, \
            idle_c=${toString idleCTimer}ms, \
            standby_z=${toString standbyZTimer}ms"
          '') devices
        )}
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };

}
