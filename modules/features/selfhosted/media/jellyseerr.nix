# seerr - media requests
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "seerr";
  subdomain = "request";
  port = 5055;
  statusPath = "/api/v1/status";

  backupServices = [ "seerr.service" ];

  homepage = {
    category = "Media";
    description = "Request media";
    icon = "sh-seerr";
  };

  oidcClient = {
    redirects = [ "/login?provider=sub0.net&callback=true" ];
    customRedirects = [ "http://request.sub0.net/login?provider=sub0.net&callback=true" ];
    extraConfig = {
      client_name = "seerr";
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
      ...
    }:
    let
      seerrOIDC =
        let
          src = pkgs.fetchFromGitHub {
            owner = "fallenbagel";
            repo = "jellyseerr";
            rev = "39b6f47c104f9f0356bf51c6cb7e3996f154a8c2";
            hash = "sha256-iBnO0WjNqvXfuJMoS6z/NmYgtW5FQ9Ptp9uV5rODIf8=";
          };
        in
        pkgs.seerr.overrideAttrs (oldAttrs: {
          inherit src;
          version = "1.9.2-oidc";
          pnpmDeps = oldAttrs.pnpmDeps.overrideAttrs (_oldDepAttrs: {
            inherit src;
            outputHash = "sha256-lq/b2PqQHsZmnw91Ad4h1uxZXsPATSLqIdb/t2EsmMI=";
          });
        });
    in
    {
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (pkgs.lib.getName pkg) [ "seerr" ];

      nixarr.seerr = {
        enable = true;
        port = 5055;
        package = seerrOIDC;
      };
    };
}
