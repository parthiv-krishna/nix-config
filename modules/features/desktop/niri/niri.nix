{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "niri"
  ];

  systemConfig =
    _cfg:
    { pkgs, ... }:
    {
      programs.niri = {
        enable = true;
        package = pkgs.niri;
      };

      # xdg portal so apps can interact with each other
      xdg.portal = {
        enable = true;
        extraPortals = [
          pkgs.xdg-desktop-portal-gtk
          pkgs.xdg-desktop-portal-gnome
        ];
      };

      # login screen
      services.greetd = {
        enable = true;
        settings = {
          default_session = {
            command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd niri-session";
            user = "parthiv";
          };
        };
      };

      fonts.packages = with pkgs; [
        font-awesome
      ];

      environment.systemPackages = with pkgs; [
        brightnessctl
        kdePackages.dolphin
        kitty
        niri
        niriswitcher
        nirius
        playerctl
        wl-clipboard-rs
      ];
    };

  homeConfig =
    _cfg:
    { config, pkgs, ... }:
    let
      mainMod = "Super";
      terminal = "kitty";
      renameWorkspace = pkgs.writeShellScript "rename-workspace" ''
        newname=$(echo "" | wofi --dmenu --prompt "Rename workspace" --exec-search --lines 1)
        status=$?
        if [ $status -ne 0 ] || [ -z "$newname" ]; then
          exit 0
        fi
        niri msg action set-workspace-name "$newname"
      '';
    in
    {
      # niri configuration via XDG config file
      xdg.configFile."niri/config.kdl".text = with config.colorScheme.palette; ''
        input {
            keyboard {
                xkb {
                    layout "us"
                    options "caps:escape"
                }
            }

            touchpad {
                tap
                natural-scroll
                accel-speed 0.2
            }

            mouse {
                accel-speed 0.0
            }
        }

        output "eDP-1" {
            scale 1.0
        }

        layout {
            gaps 16

            center-focused-column "never"

            preset-column-widths {
                proportion 0.5
                proportion 1.0
            }

            default-column-width { proportion 0.5; }

            focus-ring {
                width 2
                active-color "#${base0D}"
                inactive-color "#${base03}"
            }

            border {
                off
            }

            struts {
                left 0
                right 0
                top 0
                bottom 0
            }
        }

        spawn-at-startup "${pkgs.waybar}/bin/waybar"
        spawn-at-startup "${pkgs.dunst}/bin/dunst"
        spawn-at-startup "${pkgs.networkmanagerapplet}/bin/nm-applet" "--indicator"
        spawn-at-startup "${pkgs.pasystray}/bin/pasystray"
        spawn-at-startup "${pkgs.blueman}/bin/blueman-applet"

        cursor {
            xcursor-size 24
            xcursor-theme "default"
        }

        environment {
            DISPLAY ":0"
            QT_QPA_PLATFORM "wayland"
            QT_WAYLAND_DISABLE_WINDOWDECORATION "1"
        }

        // prefer server-side decorations
        prefer-no-csd

        screenshot-path "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png"

        animations {
            slowdown 1.0

            workspace-switch {
                spring damping-ratio=1.0 stiffness=1000 epsilon=0.0001
            }

            window-open {
                duration-ms 150
                curve "ease-out-expo"
            }

            window-close {
                duration-ms 150
                curve "ease-out-quad"
            }

            horizontal-view-movement {
                spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
            }

            window-movement {
                spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
            }

            window-resize {
                spring damping-ratio=1.0 stiffness=800 epsilon=0.0001
            }

            config-notification-open-close {
                spring damping-ratio=0.6 stiffness=1000 epsilon=0.001
            }
        }

        window-rule {
            geometry-corner-radius 10
            clip-to-geometry true
        }

        binds {
            // General
            ${mainMod}+Return { spawn "${terminal}"; }
            ${mainMod}+Space { spawn "wofi" "--show" "drun"; }
            ${mainMod}+Comma { spawn "${renameWorkspace}"; }
            ${mainMod}+Shift+Slash { show-hotkey-overlay; }
            ${mainMod}+Q { close-window; }
            ${mainMod}+M { spawn "systemctl" "suspend"; }
            ${mainMod}+F { toggle-window-floating; }
            ${mainMod}+Shift+F { fullscreen-window; }

            // move focus
            ${mainMod}+H { focus-column-left; }
            ${mainMod}+J { focus-window-or-workspace-down; }
            ${mainMod}+K { focus-window-or-workspace-up; }
            ${mainMod}+L { focus-column-right; }

            // move windows
            ${mainMod}+Shift+H { move-column-left; }
            ${mainMod}+Shift+J { move-window-down-or-to-workspace-down; }
            ${mainMod}+Shift+K { move-window-up-or-to-workspace-up; }
            ${mainMod}+Shift+L { move-column-right; }

            // switch to specific workspace
            ${mainMod}+1 { focus-workspace 1; }
            ${mainMod}+2 { focus-workspace 2; }
            ${mainMod}+3 { focus-workspace 3; }
            ${mainMod}+4 { focus-workspace 4; }
            ${mainMod}+5 { focus-workspace 5; }
            ${mainMod}+6 { focus-workspace 6; }
            ${mainMod}+7 { focus-workspace 7; }
            ${mainMod}+8 { focus-workspace 8; }
            ${mainMod}+9 { focus-workspace 9; }
            ${mainMod}+0 { focus-workspace 10; }

            // move window to specific workspace
            ${mainMod}+Shift+1 { move-window-to-workspace 1; }
            ${mainMod}+Shift+2 { move-window-to-workspace 2; }
            ${mainMod}+Shift+3 { move-window-to-workspace 3; }
            ${mainMod}+Shift+4 { move-window-to-workspace 4; }
            ${mainMod}+Shift+5 { move-window-to-workspace 5; }
            ${mainMod}+Shift+6 { move-window-to-workspace 6; }
            ${mainMod}+Shift+7 { move-window-to-workspace 7; }
            ${mainMod}+Shift+8 { move-window-to-workspace 8; }
            ${mainMod}+Shift+9 { move-window-to-workspace 9; }
            ${mainMod}+Shift+0 { move-window-to-workspace 10; }

            // window width adjustment ${mainMod}+Minus { set-column-width "-10%"; }
            ${mainMod}+Equal { set-column-width "+10%"; }

            // consume/expel windows from column
            ${mainMod}+BracketLeft { consume-window-into-column; }
            ${mainMod}+BracketRight { expel-window-from-column; }

            // column layout
            ${mainMod}+R { switch-preset-column-width; }

            // screenshot
            Print { screenshot; }
            ${mainMod}+Print { screenshot-screen; }
            ${mainMod}+Shift+Print { screenshot-window; }

            // brightness controls
            XF86MonBrightnessUp allow-when-locked=true { spawn "brightnessctl" "-e4" "-n2" "set" "5%+"; }
            XF86MonBrightnessDown allow-when-locked=true { spawn "brightnessctl" "-e4" "-n2" "set" "5%-"; }

            // volume controls
            XF86AudioRaiseVolume allow-when-locked=true { spawn "wpctl" "set-volume" "-l" "1" "@DEFAULT_AUDIO_SINK@" "5%+"; }
            XF86AudioLowerVolume allow-when-locked=true { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
            XF86AudioMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
            XF86AudioMicMute allow-when-locked=true { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SOURCE@" "toggle"; }

            // media controls
            XF86AudioNext allow-when-locked=true { spawn "playerctl" "next"; }
            XF86AudioPrev allow-when-locked=true { spawn "playerctl" "previous"; }
            XF86AudioPlay allow-when-locked=true { spawn "playerctl" "play-pause"; }
            XF86AudioPause allow-when-locked=true { spawn "playerctl" "play-pause"; }

            // power menu / logout
            ${mainMod}+Shift+E { quit; }
        }
      '';

      fonts.fontconfig.enable = true;
    };
}
