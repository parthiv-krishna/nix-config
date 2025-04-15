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
    snapraid
  ];

  # MergerFS configuration
  fileSystems."/data" = {
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

}
