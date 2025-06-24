{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hardware.wifi;
in
{
  options.custom.hardware.wifi = {
    enable = lib.mkEnableOption "custom.wifi";
    driver = lib.mkOption {
      type = lib.types.str;
      description = "wifi driver, will be reloaded upon resume from suspend";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        networking.networkmanager = {
          enable = true;
        };

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
