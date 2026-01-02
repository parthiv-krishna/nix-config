{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.gui-apps;

  packagesWithDirs = with pkgs; [
    {
      package = brave;
      stateDir = ".config/BraveSoftware";
    }
    {
      package = discord;
      stateDir = ".config/discord";
    }
    {
      package = element-desktop;
      stateDir = ".config/Element";
    }
    {
      package = librewolf;
      stateDir = ".librewolf";
    }
    {
      package = protonmail-desktop;
      stateDir = ".config/Proton Mail";
    }
    {
      package = protonvpn-gui;
      stateDir = ".config/Proton";
    }
    {
      package = proton-pass;
      stateDir = ".config/Proton Pass";
    }
    {
      package = signal-desktop;
      stateDir = ".config/Signal";
    }
  ];

  packages = map (x: x.package) packagesWithDirs;

  persistenceDirs = map (x: x.stateDir) (
    builtins.filter (x: builtins.hasAttr "stateDir" x) packagesWithDirs
  );
in
{
  options.custom.gui-apps = {
    enable = lib.mkEnableOption "GUI applications package set";
  };

  config = lib.mkIf cfg.enable {
    home.packages = packages;

    unfree.allowedPackages = [
      "discord"
    ];

    custom.persistence.directories = persistenceDirs;

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "librewolf.desktop";
        "x-scheme-handler/http" = "librewolf.desktop";
        "x-scheme-handler/https" = "librewolf.desktop";
        "x-scheme-handler/about" = "librewolf.desktop";
        "x-scheme-handler/unknown" = "librewolf.desktop";
        "x-scheme-handler/sgnl" = "signal.desktop";
        "x-scheme-handler/signalcaptcha" = "signal.desktop";
      };
    };
  };
}
