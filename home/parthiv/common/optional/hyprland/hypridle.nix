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
          timeout = 30;
          on-timeout = "brightnessctl -s set 10";
          ignore_inhibit = true;
        }
        {
          timeout = 45;
          on-timeout = "hyprlock && hyprctl dispatch dpms off";
          on-resume = "hyprctl dispatch dpms on";
        }
        {
          timeout = 60;
          on-timeout = "systemctl suspend";
        }
      ];
    };
  };

  programs.hyprlock.enable = true;
}
