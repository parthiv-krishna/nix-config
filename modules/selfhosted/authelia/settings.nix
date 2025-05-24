{
  lib,
  config,
  instanceName,
  ...
}:
let
  stateDir = "/var/lib/authelia-${instanceName}";
in
{
  server.address = "tcp://:${toString config.constants.services.authelia.port}";
  theme = "dark";
  log = {
    level = "warn";
    format = "text";
    file_path = "${stateDir}/authelia.log";
  };
  totp.issuer = "sub0.net";
  authentication_backend.file.path = "${stateDir}/users_database.yml";
  access_control = {
    default_policy = "deny";
    rules = [
      # admins can access all domains
      {
        domain_regex = "[a-z0-9]*.${config.constants.domains.public}";
        policy = "one_factor";
        subject = [ "group:admins" ];
      }
      # group members can access the associated domain
      {
        domain_regex = "'^(?P<Group>\w+)${lib.strings.escapeRegex config.constants.domains.public}$'";
        policy = "one_factor";
      }
      # deny access to non-group domains
      {
        domain_regex = "[a-z0-9]*.${config.constants.domains.public}";
        policy = "deny";
      }
    ];
  };
  session = {
    cookies = [
      {
        name = "sub0_session";
        domain = "sub0.net";
        authelia_url = "https://auth.sub0.net";
        inactivity = "1 week";
        expiration = "3 weeks";
        remember_me = "1 month";
      }
    ];
    redis = {
      host = "localhost";
      port = config.constants.services.authelia.redis-port;
    };
  };
  regulation = {
    max_retries = 3;
    find_time = "2 minutes";
    ban_time = "5 minutes";
  };
  storage = {
    local.path = "${stateDir}/db.sqlite3";
  };
  # see https://www.authelia.com/integration/proxies/caddy/#implementation
  server.endpoints.authz.forward-auth.implementation = "ForwardAuth";
  # TODO: setup SMTP server for email
  notifier = {
    disable_startup_check = false;
    filesystem.filename = "${stateDir}/notification.txt";
  };
}
