{ lib }:
lib.custom.mkFeature {
  path = [
    "hardware"
    "bluetooth"
  ];

  systemConfig =
    _cfg:
    _:
    {
      hardware.bluetooth = {
        enable = true;
        powerOnBoot = true;
      };

      services.blueman.enable = true;
    };
}
