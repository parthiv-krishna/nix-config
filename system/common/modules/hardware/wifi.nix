{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.wifi;
in
{
  options.custom.wifi = {
    enable = lib.mkEnableOption "WiFi support";
    driver = lib.mkOption {
      type = lib.types.str;
      description = "wifi driver, will be reloaded upon resume from suspend";
      example = "mt7921e";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        networking.networkmanager = {
          enable = true;
        };

        # fixes wifi disappearing after suspend/resume
        systemd.services."wifi-reload" = {
          description = "Reload ${cfg.driver} wifi driver after resume";
          wantedBy = [ "sleep.target" ];
          after = [ "sleep.target" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${pkgs.writeShellScriptBin "wifi-reload.sh" ''
              ${pkgs.kmod}/bin/modprobe -rv ${cfg.driver}
              sleep 1
              ${pkgs.kmod}/bin/modprobe -v ${cfg.driver}
            ''}/bin/wifi-reload.sh";
          };
        };

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
  );
}
