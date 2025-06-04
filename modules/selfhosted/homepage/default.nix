{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) domains;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "homepage";
  hostName = "nimbus";
  subdomain = ""; # on root domain
  public = true;
  protected = true;
  serviceConfig = lib.mkMerge [
    {
      services.homepage-dashboard = {
        enable = true;
        listenPort = config.constants.ports.homepage;
        allowedHosts = domains.public;

        # TODO: generate names in a better way. constants?
        services = [
          {
            "Media" = [
              {
                "Jellyfin: tv.${domains.public}" = {
                  description = "Movies and Shows";
                  href = "https://tv.${domains.public}";
                  icon = "sh-jellyfin";
                  ping = "midnight.${domains.internal}";
                };
              }
            ];
          }
          {
            "Storage" = [
              {
                "Immich: photos.${domains.public}" = {
                  description = "Photo Storage";
                  href = "https://photos.${domains.public}";
                  icon = "sh-immich";
                  ping = "midnight.${domains.internal}";
                };
              }
            ];
          }
          {
            "Productivity" = [
              {
                "Actual: actual.${domains.public}" = {
                  description = "Budget App";
                  href = "https://actual.${domains.public}";
                  icon = "sh-actual-budget";
                  ping = "nimbus.${domains.internal}";
                };
              }
            ];
          }
          {
            "Network" = [
              {
                "Thaw: thaw.${domains.public}" = {
                  description = "Wake up sleeping servers";
                  href = "https://thaw.${domains.public}";
                  icon = "mdi-snowflake-melt";
                  ping = "vardar.${domains.internal}";
                };
              }
            ];
          }
        ];

        settings = {
          title = "${domains.public} Dashboard";
          description = "${domains.public} Dashboard";
          background = {
            image = "https://images.unsplash.com/photo-1514903936-98502c8f016f?q=80&w=2574&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D";
            blur = "xs";
            saturate = 50;
            brightness = 50;
            opacity = 50;
          };
          statusStyle = "dot";
          theme = "dark";
          color = "sky";
          hideVersion = true;
        };

        widgets = [
          {
            resources = {
              cpu = true;
              disk = "/";
              memory = true;
            };
          }
        ];
      };

      # add ping to PATH
      # TODO: contribute back to nixpkgs? how?
      systemd.services.homepage-dashboard.environment.PATH = lib.mkForce "${lib.makeBinPath [
        pkgs.iputils
        pkgs.coreutils
        pkgs.findutils
        pkgs.gnugrep
        pkgs.gnused
        pkgs.systemd
      ]}";
    }
  ];
}
