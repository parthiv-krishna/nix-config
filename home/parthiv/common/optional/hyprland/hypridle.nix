_: {
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
          timeout = 240;
          on-timeout = "brightnessctl -s set 10";
          on-resume = "brightnessctl -r";
          ignore_inhibit = true;
        }
        {
          timeout = 300;
          on-timeout = "hyprlock && hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 600;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  programs.hyprlock.enable = true;
}
