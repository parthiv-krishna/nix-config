# Bazarr - subtitle management
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "bazarr";
  subdomain = "subtitles";
  port = 6767;
  statusPath = "/ping";

  backupServices = [ "bazarr.service" ];

  homepage = {
    category = "Media Management";
    description = "Manage subtitles";
    icon = "sh-bazarr";
  };

  vpn = {
    enable = true;
    namespace = "wg";
  };

  persistentDirectories = [
    {
      directory = "/var/lib/media/state/bazarr";
      user = "bazarr";
      group = "media";
    }
  ];

  serviceConfig = _cfg: _: {
    services.bazarr = {
      enable = true;
      group = "media";
    };
    # Bazarr doesn't have dataDir option, override working directory
    systemd.services.bazarr.serviceConfig.WorkingDirectory = lib.mkForce "/var/lib/media/state/bazarr";
  };
}
