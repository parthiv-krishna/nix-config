{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "auto-upgrade"
  ];

  extraOptions = {
    dates = lib.mkOption {
      type = lib.types.str;
      default = "05:00";
      description = "systemd calendar expression for automatic upgrades";
    };

    flake = lib.mkOption {
      type = lib.types.str;
      default = "github:parthiv-krishna/nix-config/built";
      description = "Flake URI used for auto upgrades";
    };
  };

  systemConfig =
    cfg:
    { config, pkgs, ... }:
    {
      system.autoUpgrade = {
        enable = true;
        flake = "${cfg.flake}#${config.networking.hostName}";
        # force copying build from cache.sub0.net
        flags = [
          "-L"
          "--builders"
          "''"
          "--max-jobs"
          "0"
          "--option"
          "fallback"
          "false"
          "--option"
          "always-allow-substitutes"
          "true"
        ];
        inherit (cfg) dates;
        randomizedDelaySec = "45min";
        persistent = true;
      };

      # garbage collection after auto-upgrade
      systemd.services = {
        nix-gc-after-upgrade = {
          description = "Nix garbage collection after auto-upgrade";
          serviceConfig = {
            Type = "oneshot";
            User = "root";
            ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 10d";
          };
        };

        nixos-upgrade = {
          onSuccess = [ "nix-gc-after-upgrade.service" ];
        };
      };

      custom.features.meta.zulip-notifiers.notifiers = {
        nixos-upgrade.enable = true;
        nix-gc-after-upgrade.enable = true;
      };

      programs.ssh.knownHosts = {
        "github.com" = {
          hostNames = [ "github.com" ];
          publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
        };
      };
    };

  homeConfig =
    cfg:
    {
      config,
      lib,
      osConfig ? null,
      pkgs,
      ...
    }:
    let
      flakeTarget = "${cfg.flake}#${config.home.username}";
      hmAutoUpgrade = pkgs.writeShellApplication {
        name = "home-manager-auto-upgrade";
        runtimeInputs = [
          config.programs.home-manager.package
          pkgs.nix
        ];
        text = ''
          home-manager switch \
            --flake ${lib.escapeShellArg flakeTarget} \
            -L \
            --option always-allow-substitutes true
        '';
      };
    in
    lib.optionalAttrs (osConfig == null) {
      systemd.user = {
        services.home-manager-auto-upgrade = {
          Unit.Description = "Home Manager automatic upgrade";
          Service = {
            Type = "oneshot";
            ExecStart = "${hmAutoUpgrade}/bin/home-manager-auto-upgrade";
          };
        };

        timers.home-manager-auto-upgrade = {
          Unit.Description = "Home Manager automatic upgrade timer";
          Timer = {
            OnCalendar = cfg.dates;
            RandomizedDelaySec = "45min";
            Persistent = true;
          };
          Install.WantedBy = [ "timers.target" ];
        };
      };
    };
}
