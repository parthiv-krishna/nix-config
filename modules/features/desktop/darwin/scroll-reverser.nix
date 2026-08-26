{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "darwin"
    "scroll-reverser"
  ];

  darwinConfig = _cfg: _: {
    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = lib.mkDefault true;
  };

  homeConfig =
    _cfg:
    { pkgs, ... }:
    let
      # fix mac GateKeeper verification
      scrollReverser = pkgs.scroll-reverser.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          rm -f "$out/Applications/Scroll Reverser.app/Contents/Resources/._IntroShot.png"
        '';
      });
    in
    {
      home.packages = [ scrollReverser ];

      targets.darwin.defaults."com.pilotmoon.scroll-reverser" = {
        InvertScrollingOn = true;
        ReverseMouse = true;
        ReverseTrackpad = false;
        ReverseX = false;
        ReverseY = true;
      };

      launchd.agents.scroll-reverser = {
        enable = true;
        config = {
          ProgramArguments = [
            "${scrollReverser}/Applications/Scroll Reverser.app/Contents/MacOS/Scroll Reverser"
          ];
          ProcessType = "Interactive";
          RunAtLoad = true;
        };
      };
    };
}
