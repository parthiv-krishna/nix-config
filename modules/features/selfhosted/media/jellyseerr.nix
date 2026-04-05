# Jellyseerr - media requests with OIDC support
{ lib, inputs }:
let
  stateDir = "/var/lib/media/state/jellyseerr";
  port = 5055;
in
lib.custom.mkSelfHostedFeature {
  name = "jellyseerr";
  subdomain = "request";
  inherit port;
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

  persistentDirectories = [
    {
      directory = stateDir;
      user = "jellyseerr";
      group = "jellyseerr";
    }
  ];

  serviceConfig =
    _cfg:
    { pkgs, ... }:
    let
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

      users.users.jellyseerr = {
        isSystemUser = true;
        group = "jellyseerr";
      };
      users.groups.jellyseerr = { };

      systemd.services.jellyseerr = {
        description = "Jellyseerr, a requests manager for Jellyfin (with OIDC)";
        after = [ "network.target" ];
        wantedBy = [ "multi-user.target" ];
        environment = {
          PORT = toString port;
          CONFIG_DIRECTORY = stateDir;
        };
        serviceConfig = {
          Type = "exec";
          User = "jellyseerr";
          Group = "jellyseerr";
          ExecStart = lib.getExe jellyseerrOIDC;
          Restart = "on-failure";
          ProtectHome = true;
          PrivateTmp = true;
          ProtectSystem = "strict";
          ReadWritePaths = [ stateDir ];
        };
      };
    };
}
