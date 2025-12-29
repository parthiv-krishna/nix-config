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
  host = hosts.midnight;
  inherit port;
  subdomain = "books";
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

    # disable calibre tests
    # TODO: re-enable
    nixpkgs.overlays = [
      (_: prev: {
        calibre = prev.calibre.overrideAttrs (_: {
          doCheck = false;
          doInstallCheck = false;
          checkPhase = "echo skipping tests for calibre";
          installCheckPhase = "echo skipping tests for calibre";
        });
      })
    ];

    environment.systemPackages = with pkgs; [
      calibre
    ];
  };
}
