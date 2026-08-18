# SearXNG - privacy-respecting metasearch engine
{ lib }:
let
  port = 8888;
in
lib.custom.mkSelfHostedFeature {
  name = "searx";
  subdomain = "search";
  inherit port;
  statusPath = "/healthz";
  vpn = true;

  homepage = categories: {
    category = categories.tools;
    description = "Private search engine";
    icon = "sh-searxng";
  };

  persistentDirectories = [ "/var/cache/private/searx" ];

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    let
      secretsRoot = "searx";
    in
    {
      services.searx = {
        enable = true;
        environmentFile = config.sops.templates."searx/environment".path;
        settings = {
          general.instance_name = "${config.constants.domains.public} Search";
          search = {
            autocomplete = "duckduckgo";
            formats = [
              "html"
              "json"
            ];
          };
          server = {
            inherit port;
            bind_address =
              config.vpnNamespaces.${config.custom.features.networking.vpn.namespace}.namespaceAddress;
            base_url = "${lib.custom.mkPublicHttpsUrl config.constants "search"}/";
            secret_key = "$SEARX_SECRET_KEY";
          };
        };
      };

      sops = {
        templates."searx/environment" = {
          content = ''
            SEARX_SECRET_KEY=${config.sops.placeholder."${secretsRoot}/secret_key"}
          '';
          owner = "searx";
          group = "searx";
          mode = "0400";
        };
        secrets."${secretsRoot}/secret_key" = {
          owner = "searx";
          group = "searx";
          mode = "0400";
        };
      };
    };
}
