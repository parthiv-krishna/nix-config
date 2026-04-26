{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "hyprland"
    "hypridle"
  ];

  homeConfig =
    _cfg:
    { config, ... }:
    let
      inherit (config.custom.features.desktop) idleMinutes;
    in
    {
      # lock after inactivity
      services.hypridle = {
        enable = true;
        settings = {
          general = {
            lock_cmd = "hyprlock";
            before_sleep_cmd = "hyprlock";
            after_sleep_cmd = "hyprctl dispatch dpms on";
          };
          listener = [
            {
              # dim screen before lock
              timeout = (idleMinutes.lock * 60 * 4) / 5;
              on-timeout = "brightnessctl -s set 10";
              on-resume = "brightnessctl -r";
              ignore_inhibit = true;
            }
            {
              timeout = idleMinutes.lock * 60;
              on-timeout = "hyprlock";
              on-resume = "hyprctl dispatch dpms on";
              ignore_inhibit = true;
            }
            {
              timeout = idleMinutes.screenOff * 60;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
              ignore_inhibit = true;
            }
            {
              timeout = idleMinutes.suspend * 60;
              on-timeout = "systemctl suspend";
              ignore_inhibit = true;
            }
          ];
        };
      };

      programs.hyprlock.enable = true;
    };
}
