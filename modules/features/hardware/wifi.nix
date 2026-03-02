{ lib }:
lib.custom.mkFeature {
  path = [ "hardware" "wifi" ];

  extraOptions = {
    driver = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "wifi driver, will be reloaded upon resume from suspend";
      example = "mt7921e";
    };
  };

  systemConfig = cfg: { pkgs, ... }: lib.mkMerge [
    {
      networking.networkmanager = {
        enable = true;
      };

      hardware.wirelessRegulatoryDatabase = true;
      boot.extraModprobeConfig = ''
        options cfg80211 ieee80211_regdom="US"
      '';

      # easily reload wifi driver if needed
      systemd.services."wifi-reload" = {
        description = "Reload ${cfg.driver} wifi driver after resume";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.writeShellScriptBin "wifi-reload.sh" ''
            ${pkgs.systemd}/bin/systemctl stop NetworkManager.service
            ${pkgs.systemd}/bin/systemctl stop wpa_supplicant.service
            ${pkgs.kmod}/bin/modprobe -rv ${cfg.driver}
            sleep 1
            ${pkgs.kmod}/bin/modprobe -v ${cfg.driver}
            ${pkgs.systemd}/bin/systemctl start wpa_supplicant.service
            ${pkgs.systemd}/bin/systemctl start NetworkManager.service
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
  ];
}
