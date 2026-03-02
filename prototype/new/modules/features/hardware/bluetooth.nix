# Bluetooth feature - system-only
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
      hardware.bluetooth.enable = true;
      services.blueman.enable = true;
    };
}
