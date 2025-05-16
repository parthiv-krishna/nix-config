{ config, lib, pkgs, ... }:
let
  targetHost = "nimbus";
in
{
  config = lib.mkIf (config.networking.hostName == targetHost) {
    services.actual = {
      enable = true;
      dataDir = "/var/lib/actual";
      listenAddress = "0.0.0.0";
      port = 5006;
      openFirewall = true;
    };

    environment.persistence."/persist".directories = lib.mkIf (config.boot.persistence ? "/persist") [
      "/var/lib/actual"
    ];
  };
} 