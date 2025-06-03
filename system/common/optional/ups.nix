{
  config,
  pkgs,
  ...
}:
let
  name = "ups";
  user = "upsmon";
  monitor = "mon";
  passwordKey = "ups/password";
  passwordFile = config.sops.secrets.${passwordKey}.path;
in
{
  environment.systemPackages = with pkgs; [
    nut
  ];

  power.ups = {
    enable = true;
    mode = "netserver";
    ups.${name} = {
      driver = "usbhid-ups";
      port = "auto";
      description = "USB HID UPS";
    };
    users.${user} = {
      inherit passwordFile;
      upsmon = "primary";
    };
    upsmon = {
      enable = true;
      monitor.${monitor} = {
        system = "${name}@localhost";
        inherit user passwordFile;
        type = "primary";
        powerValue = 1;
      };
    };
    openFirewall = true;
  };

  sops.secrets.${passwordKey} = { };
}
