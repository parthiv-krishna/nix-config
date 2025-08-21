{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 8004;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "calibre";
  hostName = hosts.midnight;
  inherit port;
  subdomain = "books";
  public = true;
  protected = true;
  homepage = {
    category = config.constants.homepage.categories.media;
    description = "eBooks";
    icon = "sh-calibre";
  };
  persistentDirectories = [
    {
      directory = "/var/lib/calibre-web";
      user = "calibre-web";
      group = "calibre-web";
      mode = "0755";
    }
  ];
  serviceConfig = {
    services.calibre-web = {
      enable = true;
      listen = {
        inherit port;
      };
    };

    environment.systemPackages = with pkgs; [
      calibre
    ];
  };
}
