# Prometheus NUT exporter - UPS metrics
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "prometheus-nut";
  port = 9102;

  serviceConfig =
    _cfg:
    { config, pkgs, ... }:
    let
      passwordName = "ups/password";
      passwordFile = config.sops.secrets.${passwordName}.path;
    in
    {
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
        port = 9102;
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
