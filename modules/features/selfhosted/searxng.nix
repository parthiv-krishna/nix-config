# SearXNG - privacy-respecting metasearch engine
{ lib }:
let
  port = 8888;
in
lib.custom.mkSelfHostedFeature {
  name = "searxng";
  subdomain = "search";
  inherit port;
  statusPath = "/healthz";

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
      secretsRoot = "searxng";
    in
    {
      services.searx = {
        enable = true;
        environmentFile = config.sops.templates."searxng/environment".path;
        settings = {
          general.instance_name = "${config.constants.domains.public} Search";
          server = {
            inherit port;
            bind_address = "127.0.0.1";
            base_url = "${lib.custom.mkPublicHttpsUrl config.constants "search"}/";
            secret_key = "$SEARX_SECRET_KEY";
          };
        };
      };

      sops = {
        templates."searxng/environment" = {
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
