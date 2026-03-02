{ lib }:
lib.custom.mkFeature {
  path = [ "hardware" "wake-on-lan" ];

  extraOptions = {
    device = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "device to enable Wake on LAN for";
      example = "enp2s0";
    };
  };

  systemConfig = cfg: { pkgs, ... }: lib.mkMerge [
    {
      # enable wake on LAN
      networking.interfaces."${cfg.device}".wakeOnLan = {
        enable = true;
        policy = [ "magic" ];
      };

      environment.systemPackages = with pkgs; [
        ethtool
      ];

      systemd.services.enable-wol = {
        description = "Enable Wake-on-LAN";
        wantedBy = [ "multi-user.target" ];
        after = [ "network.target" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.ethtool}/bin/ethtool -s ${cfg.device} wol g";
        };
      };

    }
  ];
}
