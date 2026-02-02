{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.hyprland;
in
lib.mkIf cfg.enable {
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
          timeout = 100 * 60;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
          ignore_inhibit = true;
        }
        {
          timeout = 150 * 60;
          on-timeout = "hyprlock";
          on-resume = "hyprctl dispatch dpms on";
          ignore_inhibit = true;
        }
        {
          timeout = 200 * 60;
          on-timeout = "systemctl suspend";
          ignore_inhibit = true;
        }
      ];
    };
  };

  programs.hyprlock.enable = true;
}
