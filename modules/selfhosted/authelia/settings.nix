_: {
  server.address = "tcp://:9091";
  theme = "dark";
  log = {
    level = "warn";
    format = "text";
    file_path = "/log/authelia.log";
  };
  totp.issuer = "sub0.net";
  identity_validation.reset_password.jwt_secret = "@jwtSecretFile@";
  authentication_backend.file.path = "/data/users_database.yml";
  access_control = {
    default_policy = "deny";
    rules = [
      {
        domain_regex = "[a-z0-9]*.sub0.net";
        policy = "bypass";
      }
    ];
  };
  session = {
    secret = "@sessionSecretFile@";
    cookies = [
      {
        name = "sub0_session";
        domain = "sub0.net";
        authelia_url = "https://auth.sub0.net";
        expiration = "1 hour";
        inactivity = "5 minutes";
      }
    ];
    redis = {
      host = "redis";
      port = 6379;
      password = "@redisPasswordFile@";
    };
  };
  regulation = {
    max_retries = 3;
    find_time = "2 minutes";
    ban_time = "5 minutes";
  };
  storage = {
    encryption_key = "@storageEncryptionKeyFile@";
    local.path = "/data/db.sqlite3";
  };
  # TODO: setup SMTP server for email
  notifier = {
    disable_startup_check = false;
    filesystem.filename = "/data/notification.txt";
  };
  identity_providers.oidc = {
    hmac_secret = "@oidcHmacSecretFile@";
    jwks = [
      {
        algorithm = "RS256";
        use = "sig";
        key = "@oidcJwksKeyFile@";
      }
    ];
    clients = [
      {
        client_name = "Actual";
        client_id = "@oidcClients.actual.idFile@";
        client_secret = "@oidcClients.actual.secretFile@";
        public = false;
        authorization_policy = "one_factor";
        redirect_uris = [ "https://actual.sub0.net/openid/callback" ];
        scopes = [
          "email"
          "groups"
          "openid"
          "profile"
        ];
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_basic";
      }
      {
        client_name = "Immich";
        client_id = "@oidcClients.immich.idFile@";
        client_secret = "@oidcClients.immich.secretFile@";
        public = false;
        authorization_policy = "one_factor";
        redirect_uris = [
          "https://immich.sub0.net/auth/login"
          "https://immich.sub0.net/user-settings"
          "app.immich:///oauth-callback"
        ];
        scopes = [
          "openid"
          "profile"
          "email"
        ];
        userinfo_signed_response_alg = "none";
      }
      {
        client_name = "Jellyfin";
        client_id = "@oidcClients.jellyfin.idFile@";
        client_secret = "@oidcClients.jellyfin.secretFile@";
        public = false;
        authorization_policy = "one_factor";
        require_pkce = true;
        redirect_uris = [ "https://jellyfin.sub0.net/sso/OID/redirect/authelia" ];
        scopes = [
          "groups"
          "openid"
          "profile"
        ];
        userinfo_signed_response_alg = "none";
        token_endpoint_auth_method = "client_secret_post";
      }
    ];
  };
}
