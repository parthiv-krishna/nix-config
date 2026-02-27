# Librewolf privacy-focused browser feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "librewolf" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.librewolf ];

    custom.features.meta.impermanence.directories = [
      ".librewolf"
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = "librewolf.desktop";
        "text/html" = "librewolf.desktop";
        "x-scheme-handler/about" = "librewolf.desktop";
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
        "x-scheme-handler/unknown" = "librewolf.desktop";
      };
    };
  };
}
