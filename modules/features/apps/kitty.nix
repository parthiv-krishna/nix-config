{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "kitty"
  ];

  homeConfig =
    _cfg:
    { config, ... }:
    {
      programs.kitty = {
        enable = true;

        settings = with config.colorScheme.palette; {
          # font
          font_family = config.custom.font.monoFamily;
          font_size = config.custom.font.sizes.normal;
          bold_font = "auto";
          italic_font = "auto";
          bold_italic_font = "auto";

          # windows
          window_padding_width = 10;
          window_border_width = "1pt";
          single_window_margin_width = 0;
          placement_strategy = "center";

          # tabs
          tab_bar_edge = "bottom";
          tab_bar_style = "powerline";
          tab_powerline_style = "slanted";
          tab_title_template = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";

          # performance
          repaint_delay = 10;
          input_delay = 3;
          sync_to_monitor = true;

          # cursor
          cursor_shape = "block";
          cursor_blink_interval = "-1";
          cursor_stop_blinking_after = "15.0";

          # mouse
          mouse_hide_wait = "3.0";
          detect_urls = true;

          # bell
          enable_audio_bell = true;
          visual_bell_duration = "0.0";
          window_alert_on_bell = true;
          bell_on_tab = true;
          command_on_bell = "none";

          # window management
          remember_window_size = true;
          initial_window_width = "80c";
          initial_window_height = "24c";
          enabled_layouts = "*";

          # advanced
          shell = ".";
          editor = ".";
          close_on_child_death = false;
          allow_remote_control = false;
          update_check_interval = 24;
          startup_session = "none";
          clipboard_control = "write-clipboard write-primary";
          allow_hyperlinks = true;

          # color scheme
          foreground = "#${base05}";
          background = "#${base00}";
          selection_foreground = "#${base00}";
          selection_background = "#${base05}";

          # cursor
          cursor = "#${base05}";
          cursor_text_color = "#${base00}";

          # url
          url_color = "#${base0D}";
          url_style = "curly";
          open_url_with = "default";

          # colors
          active_border_color = "#${base0D}";
          inactive_border_color = "#${base03}";
          bell_border_color = "#${base08}";
          active_tab_foreground = "#${base00}";
          active_tab_background = "#${base0D}";
          inactive_tab_foreground = "#${base05}";
          inactive_tab_background = "#${base01}";
          tab_bar_background = "#${base00}";
          mark1_foreground = "#${base00}";
          mark1_background = "#${base0C}";
          mark2_foreground = "#${base00}";
          mark2_background = "#${base0E}";
          mark3_foreground = "#${base00}";
          mark3_background = "#${base0A}";

          # terminal black
          color0 = "#${base00}";
          color8 = "#${base03}";

          # terminal red
          color1 = "#${base08}";
          color9 = "#${base08}";

          # terminal green
          color2 = "#${base0B}";
          color10 = "#${base0B}";

          # terminal yellow
          color3 = "#${base0A}";
          color11 = "#${base0A}";

          # terminal blue
          color4 = "#${base0D}";
          color12 = "#${base0D}";

          # terminal magenta
          color5 = "#${base0E}";
          color13 = "#${base0E}";

          # terminal cyan
          color6 = "#${base0C}";
          color14 = "#${base0C}";

          # terminal white
          color7 = "#${base05}";
          color15 = "#${base07}";
        };

        shellIntegration.enableBashIntegration = true;
      };

      programs.bash.shellAliases.ssh = "kitten ssh";
    };
}
