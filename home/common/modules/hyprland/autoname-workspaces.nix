{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hyprland;
  tomlFormat = pkgs.formats.toml { };
in
lib.mkIf cfg.enable {
  home.packages = with pkgs; [
    hyprland-autoname-workspaces
  ];

  xdg.configFile."hyprland-autoname-workspaces/config.toml".source =
    tomlFormat.generate "hyprland-autoname-workspaces-config"
      {
        format = {
          dedup = true;
          delim = " ";
          client = "{icon}{delim}";
          client_active = "<span color='#00ff00'>{icon}</span>{delim}";
          workspace = "{id}: {clients}";
          workspace_empty = "{id}";
        };

        class = {
          DEFAULT = "";
          "(?i)librewolf" = "<span color='#ff6b35'>󰖟</span>";
          "(?i)kitty" = "<span color='#4a90e2'></span>";
          "(?i)spotify" = "<span color='#1db954'></span>";
          "(?i)discord" = "<span color='#7289da'></span>";
          "(?i)signal" = "<span color='#3a76f0'></span>";
        };

        class_active = {
          DEFAULT = "{icon}";
          "(?i)librewolf" = "<span color='#ff6b35'>󰖟</span>";
          "(?i)kitty" = "<span color='#4a90e2'></span>";
          "(?i)spotify" = "<span color='#1db954'></span>";
          "(?i)discord" = "<span color='#7289da'></span>";
          "(?i)signal" = "<span color='#3a76f0'></span>";
        };

        title_in_class = {
          "(?i)kitty" = {
            "(.{1,20}).*" = "<span color='#4a90e2'>{match1}</span>";
          };
          "(?i)librewolf" = {
            "(.{1,20}).*" = "<span color='#ff6b35'>󰖟{match1}</span>";
          };
        };

        title_active = {
          "(?i)kitty" = {
            "(.{1,20}).*" = "<span color='#4a90e2'>{match1}</span>";
          };
          "(?i)librewolf" = {
            "(.{1,20}).*" = "<span color='#ff6b35'>󰖟{match1}</span>";
          };
        };
      };

  wayland.windowManager.hyprland.settings.exec-once = [
    "hyprland-autoname-workspaces"
  ];
}
