# UPS support feature (direct-attached) - system-only
{ lib }:
lib.custom.mkFeature {
  path = [ "hardware" "ups" ];

  extraOptions = {
    name = lib.mkOption {
      type = lib.types.str;
      description = "name for the UPS";
      default = "ups";
    };
    user = lib.mkOption {
      type = lib.types.str;
      description = "name for the UPS";
      default = "upsmon";
    };
    monitor = lib.mkOption {
      type = lib.types.str;
      description = "name for the monitor";
      default = "mon";
    };
    passwordKey = lib.mkOption {
      type = lib.types.str;
      description = "sops-nix key for the password file";
      default = "ups/password";
    };
  };

  systemConfig = cfg: { config, pkgs, ... }: let
    passwordFile = config.sops.secrets.${cfg.passwordKey}.path;
  in lib.mkMerge [
    {
      environment.systemPackages = with pkgs; [
        nut
      ];

      power.ups = {
        enable = true;
        mode = "netserver";
        ups.${cfg.name} = {
          driver = "usbhid-ups";
          port = "auto";
          description = "USB HID UPS";
        };
        users.${cfg.user} = {
          inherit passwordFile;
          upsmon = "primary";
        };
        upsmon = {
          enable = true;
          monitor.${cfg.monitor} = {
            system = "${cfg.name}@localhost";
            inherit (cfg) user;
            inherit passwordFile;
            type = "primary";
            powerValue = 1;
          };
        };
        openFirewall = true;
      };

      sops.secrets.${cfg.passwordKey} = { };
    }
  ];
}
