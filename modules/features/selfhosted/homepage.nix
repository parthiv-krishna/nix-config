# Homepage dashboard
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "homepage";
  subdomain = ""; # On root domain
  port = 8082;

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    let
      inherit (config.constants) domains;
    in
    {
      services.homepage-dashboard = {
        enable = true;
        listenPort = 8082;
        allowedHosts = domains.public;

        # Automatically generate services defined by other selfhosted features
        services =
          let
            inherit (config.custom.features.selfhosted) serviceMetadata homepageMetadata;

            # Only show services that have both serviceMetadata AND homepageMetadata
            servicesWithHomepage = lib.filterAttrs (name: _: homepageMetadata ? ${name}) serviceMetadata;

            servicesByCategory = lib.foldl' (
              acc: serviceName:
              let
                svc = serviceMetadata.${serviceName};
                hp = homepageMetadata.${serviceName};
                baseUrl = lib.custom.mkPublicHttpsUrl config.constants svc.subdomain;
                entryAttrs = {
                  inherit (hp) description icon;
                  href = baseUrl;
                }
                // lib.optionalAttrs (svc.statusPath != null) {
                  siteMonitor = "${baseUrl}${svc.statusPath}";
                };
                entry = {
                  "${svc.name}: ${svc.subdomain}.${domains.public}" = entryAttrs;
                };
              in
              acc
              // {
                ${hp.category} = (acc.${hp.category} or [ ]) ++ [ entry ];
              }
            ) { } (builtins.attrNames servicesWithHomepage);

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
              builtins.map (category: { ${category} = servicesByCategory.${category} or [ ]; }) categories
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
