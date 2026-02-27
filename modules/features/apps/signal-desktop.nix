# Signal encrypted messenger feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "signal-desktop" ];

  homeConfig = cfg: { pkgs, ... }: {
    home.packages = [ pkgs.signal-desktop ];

    custom.features.meta.impermanence.directories = [
      ".config/Signal"
    ];

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/sgnl" = "signal.desktop";
        "x-scheme-handler/signalcaptcha" = "signal.desktop";
      };
    };
  };
}
