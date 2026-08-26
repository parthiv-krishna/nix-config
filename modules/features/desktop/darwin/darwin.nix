{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "darwin"
  ];

  darwinConfig = _cfg: _: {
    system = {
      keyboard = {
        enableKeyMapping = lib.mkDefault true;
        remapCapsLockToEscape = lib.mkDefault true;
      };

      defaults = {
        NSGlobalDomain = {
          AppleKeyboardUIMode = lib.mkDefault 3;
          ApplePressAndHoldEnabled = lib.mkDefault false;
          InitialKeyRepeat = lib.mkDefault 15;
          KeyRepeat = lib.mkDefault 2;
          NSAutomaticCapitalizationEnabled = lib.mkDefault false;
          NSAutomaticDashSubstitutionEnabled = lib.mkDefault false;
          NSAutomaticPeriodSubstitutionEnabled = lib.mkDefault false;
          NSAutomaticQuoteSubstitutionEnabled = lib.mkDefault false;
          NSAutomaticSpellingCorrectionEnabled = lib.mkDefault false;
        };

        dock = {
          autohide = lib.mkDefault true;
          autohide-delay = lib.mkDefault 0.0;
          autohide-time-modifier = lib.mkDefault 0.2;
          mru-spaces = lib.mkDefault false;
          orientation = lib.mkDefault "bottom";
          persistent-apps = lib.mkDefault [
            "/Users/parthiv/Applications/Home Manager Apps/kitty.app"
            "/Users/parthiv/Applications/Home Manager Apps/LibreWolf.app"
            { spacer.small = true; }
            "/System/Applications/Messages.app"
            "/System/Applications/FaceTime.app"
            "/Users/parthiv/Applications/Home Manager Apps/Signal.app"
            { spacer.small = true; }
            "/Users/parthiv/Applications/Home Manager Apps/Proton Mail.app"
            "/Applications/Proton Drive.app"
            "/Users/parthiv/Applications/Home Manager Apps/ProtonVPN.app"
            "/Users/parthiv/Applications/Home Manager Apps/Proton Pass.app"
            { spacer.small = true; }
            "/Applications/Pro Tools.app"
            "/Users/parthiv/Applications/Home Manager Apps/Reaper.app"
            "/Applications/Focusrite Control 2.app"
            { spacer.small = true; }
          ];
          show-recents = lib.mkDefault false;
          tilesize = lib.mkDefault 48;
        };

        finder = {
          AppleShowAllExtensions = lib.mkDefault true;
          AppleShowAllFiles = lib.mkDefault true;
          FXEnableExtensionChangeWarning = lib.mkDefault false;
          FXPreferredViewStyle = lib.mkDefault "clmv";
          FXRemoveOldTrashItems = lib.mkDefault true;
          ShowPathbar = lib.mkDefault true;
          ShowStatusBar = lib.mkDefault true;
          _FXSortFoldersFirst = lib.mkDefault true;
        };

        trackpad = {
          Clicking = lib.mkDefault true;
          TrackpadThreeFingerDrag = lib.mkDefault true;
        };
      };
    };
  };
}
