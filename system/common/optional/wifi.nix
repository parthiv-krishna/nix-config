{
  lib,
  ...
}:
lib.mkMerge [
  {
    networking.networkmanager.enable = true;
  }
  (lib.custom.mkPersistentSystemDir {
    directory = "/var/lib/NetworkManager";
    user = "root";
    mode = "0755";
  })
  (lib.custom.mkPersistentSystemDir {
    directory = "/etc/NetworkManager";
    user = "root";
    mode = "0755";
  })
]
