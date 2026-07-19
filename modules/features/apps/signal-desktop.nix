{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "signal-desktop"
  ];

  homeConfig =
    _cfg:
    { lib, pkgs, ... }:
    lib.mkMerge [
      {
        home.packages = [ pkgs.signal-desktop ];

        custom.features.meta.impermanence.directories = [
          ".config/Signal"
        ];
      }

      (lib.mkIf pkgs.stdenv.isLinux {
        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/sgnl" = "signal.desktop";
            "x-scheme-handler/signalcaptcha" = "signal.desktop";
          };
        };
      })
    ];
}
