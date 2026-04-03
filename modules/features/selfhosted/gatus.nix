# Gatus - uptime monitoring dashboard
{ lib }:
let
  port = 8080;
in
lib.custom.mkSelfHostedFeature {
  name = "gatus";
  subdomain = "status";
  inherit port;
  statusPath = "/health";

  homepage = {
    category = "Network";
    description = "Uptime monitoring";
    icon = "sh-gatus";
  };

  persistentDirectories = [ "/var/lib/private/gatus" ];

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    let
      inherit (config.custom.features.selfhosted) serviceMetadata;

      # Filter to only services with statusPath defined (not null)
      monitoredServices = lib.filterAttrs (_: svc: svc.statusPath != null) serviceMetadata;
    in
    {
      services.gatus = {
        enable = true;
        settings = {
          storage = {
            type = "sqlite";
            path = "/var/lib/gatus/data.db";
          };
          web = {
            inherit port;
          };
          ui = {
            title = "Status | ${config.constants.domains.public}";
            header = "${config.constants.domains.public} Status";
          };
          endpoints = lib.mapAttrsToList (
            _name: svc:
            let
              baseUrl = lib.custom.mkPublicHttpsUrl config.constants svc.subdomain;
            in
            {
              inherit (svc) name;
              group = "services";
              url = "${baseUrl}${svc.statusPath}";
              interval = "1m";
              conditions = [
                "[STATUS] < 400"
                "[RESPONSE_TIME] < 10000"
              ];
            }
          ) monitoredServices;
        };
      };
    };
}
