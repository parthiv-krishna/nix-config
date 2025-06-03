{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    nut
  ];

  power.ups = {
    enable = true;
    mode = "netserver";
    ups = {
      ups = {
        driver = "usbhid-ups";
        port = "auto";
        description = "USB HID UPS";
      };
    };
    users = {
      upsmon = {
        passwordFile = "/tmp/upsmon-password";
        upsmon = "primary";
      };
    };
    upsmon.monitor = {
      mon = {
        system = "ups@localhost";
        user = "upsmon";
        passwordFile = "/tmp/upsmon-password";
        type = "primary";
        powerValue = 1;
      };
    };
    openFirewall = true;
  };
}
