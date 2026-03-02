{ lib }:
lib.custom.mkFeature {
  path = [ "hardware" "bluetooth" ];

  systemConfig = cfg: { ... }: {
    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    services.blueman.enable = true;
  };
}
