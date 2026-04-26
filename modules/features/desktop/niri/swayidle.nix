{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "niri"
    "swayidle"
  ];

  homeConfig =
    _cfg:
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.custom.features.desktop) idleMinutes;
      lockCmd = "${pkgs.swaylock}/bin/swaylock -f";
    in
    {
      services.swayidle = {
        enable = true;
        timeouts = [
          # dim screen before lock
          {
            timeout = (idleMinutes.lock * 60 * 4) / 5;
            command = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
            resumeCommand = "${pkgs.brightnessctl}/bin/brightnessctl -r";
          }
          # lock screen
          {
            timeout = idleMinutes.lock * 60;
            command = lockCmd;
          }
          # turn off screen
          {
            timeout = idleMinutes.screenOff * 60;
            command = "niri msg action power-off-monitors";
          }
          # suspend
          {
            timeout = idleMinutes.suspend * 60;
            command = "${pkgs.systemd}/bin/systemctl suspend";
          }
        ];
        events = {
          before-sleep = lockCmd;
          lock = lockCmd;
        };
      };

      # swaylock configuration
      programs.swaylock = {
        enable = true;
        settings = {
          color = "000000";
          font-size = 24;
          indicator-idle-visible = false;
          indicator-radius = 100;
          line-color = "ffffff";
          show-failed-attempts = true;
        };
      };
    };
}
