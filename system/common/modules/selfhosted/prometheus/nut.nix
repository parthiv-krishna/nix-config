{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) hosts;
  passwordName = "ups/password";
  passwordFile = config.sops.secrets.${passwordName}.path;
  port = 9102;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "prometheus-nut";
  hostName = hosts.midnight.name;
  inherit port;
  public = false;
  protected = false;
  serviceConfig = {
    environment.systemPackages = with pkgs; [
      nut
    ];

    power.ups = {
      enable = true;
      mode = "netserver";
      ups.ups = {
        driver = "usbhid-ups";
        port = "auto";
        description = "USB HID UPS";
      };
      users.upsmon = {
        inherit passwordFile;
        upsmon = "primary";
      };
      upsmon = {
        enable = true;
        monitor.mon = {
          system = "ups@localhost";
          user = "upsmon";
          inherit passwordFile;
          type = "primary";
          powerValue = 1;
        };
      };
    };

    services.prometheus.exporters.nut = {
      enable = true;
      inherit port;
      nutServer = "127.0.0.1";
      nutVariables = [
        "battery.charge"
        "battery.voltage"
        "battery.voltage.nominal"
        "battery.runtime"
        "input.voltage"
        "input.voltage.nominal"
        "output.voltage"
        "output.voltage.nominal"
        "ups.load"
        "ups.status"
        "ups.temperature"
        "ups.realpower"
        "battery.charge.low"
        "battery.runtime.low"
      ];
      openFirewall = false;
      passwordPath = passwordFile;
    };

    sops.secrets.${passwordName} = { };
  };
}
