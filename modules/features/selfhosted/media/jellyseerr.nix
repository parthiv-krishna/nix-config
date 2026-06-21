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
      # OIDC branch still requires pnpm 9, while upstream seerr uses pnpm 10.
      pnpm = pkgs.pnpm_9.override { nodejs-slim = pkgs.nodejs-slim_22; };
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
          pnpmDeps = pkgs.fetchPnpmDeps {
            inherit (oldAttrs) pname;
            inherit src pnpm;
            version = "1.9.2-oidc";
            fetcherVersion = 3;
            hash = "sha256-iL7N+7EP+zBWf5pDygC/qu8BgA3uhZwgbatOiLgU/wU=";
          };
          installPhase = ''
            runHook preInstall
            mkdir -p $out/share
            cp -r -t $out/share .next node_modules dist public package.json jellyseerr-api.yml
            runHook postInstall
          '';
          nativeBuildInputs =
            lib.filter (input: (input.pname or null) != "pnpm") oldAttrs.nativeBuildInputs
            ++ [ pnpm ];
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
