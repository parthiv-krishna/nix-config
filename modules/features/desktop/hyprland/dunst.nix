{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "hyprland"
    "dunst"
  ];

  homeConfig =
    _cfg:
    { config, ... }:
    {
      services.dunst = {
        enable = true;

        settings = with config.colorScheme.palette; {
          global = {
            # display
            monitor = 0;
            follow = "mouse";

            # geometry
            width = 300;
            height = 300;
            origin = "top-right";
            offset = "10x50";
            scale = 0;
            notification_limit = 0;

            # progress bar
            progress_bar = true;
            progress_bar_height = 10;
            progress_bar_frame_width = 1;
            progress_bar_min_width = 150;
            progress_bar_max_width = 300;

            # appearance
            transparency = 10;
            separator_height = 2;
            padding = 8;
            horizontal_padding = 8;
            text_icon_padding = 0;
            frame_width = 2;
            frame_color = "#${base0D}";
            separator_color = "frame";
            sort = "yes";

            # text and font
            font = "${config.custom.font.monoFamily} ${toString config.custom.font.sizes.small}";
            line_height = 0;
            markup = "full";
            format = "<b>%s</b>\\n%b";
            alignment = "left";
            vertical_alignment = "center";
            show_age_threshold = 60;
            ellipsize = "middle";
            ignore_newline = false;
            stack_duplicates = true;
            hide_duplicate_count = false;
            show_indicators = true;

            # icons
            icon_position = "left";
            min_icon_size = 0;
            max_icon_size = 32;

            # history
            sticky_history = true;
            history_length = 20;

            # misc
            dmenu = "\${pkgs.dmenu}/bin/dmenu -p dunst:";
            browser = "\${pkgs.firefox}/bin/firefox -new-tab";
            always_run_script = true;
            title = "Dunst";
            class = "Dunst";
            corner_radius = 10;
            ignore_dbusclose = false;
            force_xwayland = false;

            # mouse
            mouse_left_click = "do_action, close_current";
            mouse_middle_click = "close_all";
            mouse_right_click = "close_current";
          };

          experimental = {
            per_monitor_dpi = false;
          };

          urgency_low = {
            background = "#${base00}";
            foreground = "#${base05}";
            timeout = 10;
            default_icon = "dialog-information";
          };

          urgency_normal = {
            background = "#${base00}";
            foreground = "#${base05}";
            frame_color = "#${base0D}";
            timeout = 10;
            default_icon = "dialog-information";
          };

          urgency_critical = {
            background = "#${base08}";
            foreground = "#${base00}";
            frame_color = "#${base08}";
            timeout = 0;
            default_icon = "dialog-warning";
          };
        };
      };
    };
}
