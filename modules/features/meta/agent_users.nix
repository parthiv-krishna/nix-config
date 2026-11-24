{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "agent_users"
  ];

  extraOptions.users = lib.mkOption {
    default = { };
    description = "Agent users to create on NixOS";
    example = {
      public.groups = [ "systemd-journal" ];
    };
    type = lib.types.attrsOf (
      lib.types.submodule {
        options = {
          groups = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Supplementary groups for this agent user.";
          };
        };
      }
    );
  };

  systemConfig =
    cfg:
    { config, pkgs, ... }:
    {
      users.users = lib.mapAttrs' (
        name: user:
        lib.nameValuePair "agent-${name}" {
          isNormalUser = true;
          hashedPassword = "!";
          shell = pkgs.bashInteractive;
          extraGroups = user.groups;
          packages = with pkgs; [
            coreutils
            curl
            diffutils
            fd
            file
            findutils
            gcc
            git
            gnumake
            gnugrep
            gnused
            gnutar
            gzip
            jq
            nodejs
            openssh
            patch
            pkg-config
            python3
            ripgrep
            tree
            unzip
            wget
            which
            zip
          ];
          openssh.authorizedKeys.keys = [
            "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGz1tqNORczwdaYeC2+NGjUXYVGKBJ18KfHfQ3/V+c+2 controlroom@controlroom.sub0.net"
          ];
        }
      ) cfg.users;

      environment.persistence."/persist" = lib.mkIf config.custom.features.meta.impermanence.enable {
        hideMounts = true;
        directories = lib.mapAttrsToList (name: _: {
          directory = "/home/agent-${name}";
          user = "agent-${name}";
          group = config.users.users."agent-${name}".group;
          mode = "0700";
        }) cfg.users;
      };
    };
}
