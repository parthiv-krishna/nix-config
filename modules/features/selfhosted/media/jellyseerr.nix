# Jellyseerr - media requests
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "jellyseerr";
  subdomain = "request";
  port = 5055;
  statusPath = "/api/v1/status";

  backupServices = [ "jellyseerr.service" ];

  homepage = {
    category = "Media";
    description = "Request media";
    icon = "sh-jellyseerr";
  };

  oidcClient = {
    redirects = [ "/login?provider=sub0.net&callback=true" ];
    customRedirects = [ "http://request.sub0.net/login?provider=sub0.net&callback=true" ];
    extraConfig = {
      client_name = "Jellyseerr";
      scopes = [
        "openid"
        "email"
        "profile"
        "groups"
      ];
      authorization_policy = "one_factor";
      token_endpoint_auth_method = "client_secret_post";
    };
  };

  serviceConfig =
    _cfg:
    {
      pkgs,
      inputs,
      ...
    }:
    let
      # Use jellyseerr from pinned nixpkgs (before it was renamed to seerr)
      pkgsPinned = import inputs.nixpkgs-jellyseerr { inherit (pkgs.stdenv.hostPlatform) system; };
      jellyseerrOIDC = pkgsPinned.jellyseerr.overrideAttrs (oldAttrs: {
        src = pkgs.fetchFromGitHub {
          owner = "fallenbagel";
          repo = "jellyseerr";
          rev = "39b6f47c104f9f0356bf51c6cb7e3996f154a8c2";
          hash = "sha256-iBnO0WjNqvXfuJMoS6z/NmYgtW5FQ9Ptp9uV5rODIf8=";
        };
        version = "1.9.2-oidc";
        pnpmDeps = oldAttrs.pnpmDeps.overrideAttrs (_oldDepAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "fallenbagel";
            repo = "jellyseerr";
            rev = "39b6f47c104f9f0356bf51c6cb7e3996f154a8c2";
            hash = "sha256-iBnO0WjNqvXfuJMoS6z/NmYgtW5FQ9Ptp9uV5rODIf8=";
          };
          outputHash = "sha256-lq/b2PqQHsZmnw91Ad4h1uxZXsPATSLqIdb/t2EsmMI=";
        });
      });
    in
    {
      nixpkgs.config.allowUnfreePredicate =
        pkg: builtins.elem (pkgsPinned.lib.getName pkg) [ "jellyseerr" ];

      nixarr.jellyseerr = {
        enable = true;
        port = 5055;
        package = jellyseerrOIDC;
      };
    };
}
