{
  config,
  lib,
  ...
}:
let
  inherit (config.constants) domains hosts;
  port = 8082;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "homepage";
  host = hosts.nimbus;
  inherit port;
  subdomain = ""; # on root domain
  serviceConfig = {
    services.homepage-dashboard = {
      enable = true;
      listenPort = port;
      allowedHosts = domains.public;

      # automatically generate services defined in lib.custom.mkSelfHostedService
      services =
        let
          inherit (config.custom.selfhosted) homepageServices;

          servicesByCategory = lib.foldl' (
            acc: serviceName:
            let
              service = homepageServices.${serviceName};
              inherit (service) category;
              entry = {
                "${service.name}: ${service.subdomain}.${domains.public}" = {
                  inherit (service) description icon;
                  href = lib.custom.mkPublicHttpsUrl config.constants service.subdomain;
                  ping = lib.custom.mkInternalFqdn config.constants "" service.hostName;
                };
              };
            in
            acc
            // {
              ${category} = (acc.${category} or [ ]) ++ [ entry ];
            }
          ) { } (builtins.attrNames homepageServices);

          template = with config.constants.homepage.categories; [
            {
              "Applications" = [
                media
                storage
                tools
              ];
            }
            {
              "Administrative" = [
                network
                media-management
              ];
            }
          ];
        in
        builtins.map (
          group:
          builtins.mapAttrs (
            _groupName: categories:
            builtins.map (category: { ${category} = servicesByCategory.${category}; }) categories
          ) group
        ) template;

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
          search = {
            provider = [ "brave" ];
          };
        }
        {
          datetime = {
            text_size = "xl";
            format = {
              timeZone = "US/Pacific";
            };
          };
        }
        {
          openmeteo = {
            label = "Santa Clara, CA";
            latitude = 37.342095;
            longitude = -121.975512;
            units = "imperial";
            timezone = "US/Pacific";
            cache = 5;
          };
        }
      ];
    };
  };
}
