{
  pkgs,
  ...
}:
let
  packagesWithDirs = with pkgs; [
    {
      package = audacity;
    }
    {
      package = element;
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
  home.packages = packages;

  home.persistence."/persist/home/parthiv" = {
    directories = persistenceDirs;
    allowOther = true;
  };
}
