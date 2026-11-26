# Monica - personal CRM
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "monica";
  port = 8091;
  statusPath = "/login";

  backupServices = [
    "monica-scheduler.timer"
    "monica-scheduler.service"
    "phpfpm-monica.service"
    "mysql.service"
  ];

  homepage = categories: {
    category = categories.tools;
    description = "Personal CRM";
    icon = "sh-monica";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/monica";
      user = "monica";
      group = "monica";
      mode = "0710";
    }
    {
      directory = "/var/lib/mysql";
      user = "mysql";
      group = "mysql";
      mode = "0700";
    }
  ];

  serviceConfig =
    _cfg:
    { config, lib, ... }:
    {
      services.monica = {
        enable = true;
        hostname = lib.custom.mkPublicFqdn config.constants "monica";
        appURL = lib.custom.mkPublicHttpsUrl config.constants "monica";
        appKeyFile = config.sops.secrets."monica/app_key".path;
        nginx.listen = [
          {
            addr = "127.0.0.1";
            port = 8091;
          }
          {
            addr = "[::1]";
            port = 8091;
          }
        ];
        config = {
          SESSION_SECURE_COOKIE = lib.mkForce true;
          APP_TRUSTED_PROXIES = "127.0.0.1,::1";
          APP_DISABLE_SIGNUP = true;
          VIEW_COMPILED_PATH = "${config.services.monica.dataDir}/storage/framework/views";
        };
      };

      sops.secrets."monica/app_key" = {
        owner = "monica";
        mode = "0400";
      };
    };
}
