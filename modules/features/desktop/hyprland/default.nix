{ lib }:
lib.custom.mkFeature {
  path = [ "desktop" "hyprland" ];

  extraOptions = {
    idleMinutes = {
      lock = lib.mkOption {
        type = lib.types.int;
        default = 5;
        description = "Number of idle minutes before the screen locks.";
        example = 15;
      };
      screenOff = lib.mkOption {
        type = lib.types.int;
        default = 10;
        description = "Number of idle minutes before the screen turns off.";
        example = 30;
      };
      suspend = lib.mkOption {
        type = lib.types.int;
        default = 15;
        description = "Number of idle minutes before the system suspends.";
        example = 60;
      };
    };
  };

  # System-level configuration: hyprland, greetd login screen, system packages
  systemConfig = cfg: { config, pkgs, ... }: {
    programs.hyprland.enable = true;

    # xdg portal so apps can interact with each other
    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };

    # login screen
    services.greetd = {
      enable = true;
      settings = {
        default_session = {
          command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd ${config.programs.hyprland.package}/bin/start-hyprland";
          user = "parthiv";
        };
      };
    };

    fonts.packages = with pkgs; [
      font-awesome
    ];

    environment.systemPackages = with pkgs; [
      brightnessctl
      dunst
      kdePackages.dolphin
      kitty
      playerctl
      waybar
      wl-clipboard-rs
      wofi
    ];
  };

  # Home-level configuration: hyprland window manager settings, keybinds, colors
  homeConfig = cfg: { config, pkgs, ... }:
  let
    mainMod = "SUPER";
    terminal = "kitty";
    menu = "wofi --show drun";
    renameWorkspace = "${pkgs.writeScriptBin "rename-workspace" ''
      newname=$(wofi --show dmenu -p "Rename workspace:" < /dev/null)
      status=$?
      if [ $status -ne 0 ] || [ -z "$newname" ]; then
        # Cancelled or empty input: do nothing
        exit 0
      fi
      hyprctl dispatch renameworkspace $(hyprctl activeworkspace -j | ${pkgs.jq}/bin/jq .id) "$newname"
    ''}/bin/rename-workspace";
    # workspace keybindings (1..10)
    workspaceBinds = builtins.concatLists (
      builtins.genList (
        i:
        let
          num = if i == 9 then "0" else toString (i + 1);
          ws = toString (i + 1);
        in
        [
          # switch to workspace
          "${mainMod}, ${num}, workspace, ${ws}"
          # move window to workspace
          "${mainMod} SHIFT, ${num}, movetoworkspace, ${ws}"
        ]
      ) 10
    );
  in
  {
    wayland.windowManager.hyprland = {
      enable = true;

      settings = with config.colorScheme.palette; {
        # monitors
        monitor = ",preferred,auto,1";

        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
        ];

        general = {
          gaps_in = 5;
          gaps_out = 20;
          border_size = 2;
          resize_on_border = false;
          allow_tearing = false;
          layout = "dwindle";
          # colors using nix-colors
          "col.active_border" = "rgba(${base0D}ee) rgba(${base0B}ee) 45deg";
          "col.inactive_border" = "rgba(${base03}aa)";
        };

        decoration = {
          rounding = 10;
          active_opacity = 1.0;
          inactive_opacity = 1.0;
          shadow = {
            enabled = true;
            range = 4;
            render_power = 3;
            color = "rgba(${base00}ee)";
          };
          blur = {
            enabled = true;
            size = 3;
            passes = 1;
            vibrancy = 0.1696;
          };
        };

        animations = {
          enabled = "yes";
          bezier = [
            "easeOutQuint,0.23,1,0.32,1"
            "easeInOutCubic,0.65,0.05,0.36,1"
            "linear,0,0,1,1"
            "almostLinear,0.5,0.5,0.75,1.0"
            "quick,0.15,0,0.1,1"
          ];
          animation = [
            "global, 1, 10, default"
            "border, 1, 5.39, easeOutQuint"
            "windows, 1, 4.79, easeOutQuint"
            "windowsIn, 1, 4.1, easeOutQuint, popin 87%"
            "windowsOut, 1, 1.49, linear, popin 87%"
            "fadeIn, 1, 1.73, almostLinear"
            "fadeOut, 1, 1.46, almostLinear"
            "fade, 1, 3.03, quick"
            "layers, 1, 3.81, easeOutQuint"
            "layersIn, 1, 4, easeOutQuint, fade"
            "layersOut, 1, 1.5, linear, fade"
            "fadeLayersIn, 1, 1.79, almostLinear"
            "fadeLayersOut, 1, 1.39, almostLinear"
            "workspaces, 1, 1.94, almostLinear, fade"
            "workspacesIn, 1, 1.21, almostLinear, fade"
            "workspacesOut, 1, 1.94, almostLinear, fade"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        master = {
          new_status = "master";
        };

        misc = {
          force_default_wallpaper = 0;
          disable_hyprland_logo = true;
        };

        input = {
          kb_layout = "us";
          kb_variant = "";
          kb_model = "";
          kb_options = "caps:escape";
          kb_rules = "";
          follow_mouse = 1;
          sensitivity = 0;
          touchpad = {
            natural_scroll = true;
          };
        };

        gesture = [
          "3, horizontal, workspace"
        ];

        bind = [
          "${mainMod}, Q, killactive,"
          "${mainMod}, M, exec, systemctl suspend"
          "${mainMod}, F, togglefloating,"
          "${mainMod}, Space, exec, ${menu}"
          "${mainMod}, Return, exec, ${terminal}"
          "${mainMod}, Comma, exec, ${renameWorkspace}"
          "${mainMod}, H, movefocus, l"
          "${mainMod}, J, movefocus, d"
          "${mainMod}, K, movefocus, u"
          "${mainMod}, L, movefocus, r"
          "${mainMod} SHIFT, H, movewindow, l"
          "${mainMod} SHIFT, J, movewindow, d"
          "${mainMod} SHIFT, K, movewindow, u"
          "${mainMod} SHIFT, L, movewindow, r"
          "${mainMod}, S, togglespecialworkspace, magic"
          "${mainMod} SHIFT, S, movetoworkspace, special:magic"
          "${mainMod}, mouse_down, workspace, e+1"
          "${mainMod}, mouse_up, workspace, e-1"
          "${mainMod}, right, workspace, e+1"
          "${mainMod}, left, workspace, e-1"
          "${mainMod}, mouse:272, movewindow"
          "${mainMod}, mouse:273, resizeactive"
        ]
        ++ workspaceBinds;

        # volume and brightness
        bindel = [
          ",XF86AudioRaiseVolume, exec, wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"
          ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
          ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
          ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
          ",XF86MonBrightnessUp, exec, brightnessctl -e4 -n2 set 5%+"
          ",XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-"
        ];

        # media keys
        bindl = [
          ", XF86AudioNext, exec, playerctl next"
          ", XF86AudioPause, exec, playerctl play-pause"
          ", XF86AudioPlay, exec, playerctl play-pause"
          ", XF86AudioPrev, exec, playerctl previous"
        ];

        windowrulev2 = [
          "suppressevent maximize, class:.*"
          "nofocus,class:^$,title:^$,xwayland:1,floating:1,fullscreen:0,pinned:0"
        ];

        # disable popup at login
        ecosystem = {
          no_update_news = true;
        };
      };
    };

    home.packages = [
      config.custom.font.package
    ];

    fonts.fontconfig.enable = true;
  };
}
