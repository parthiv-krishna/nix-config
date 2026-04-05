{ lib }:
lib.custom.mkFeature {
  path = [
    "desktop"
    "waybar"
  ];

  extraOptions = {
    compositor = lib.mkOption {
      type = lib.types.enum [
        "hyprland"
        "niri"
      ];
      default = "hyprland";
      description = "Which compositor to configure waybar for.";
    };
  };

  homeConfig =
    cfg:
    { config, pkgs, ... }:
    let
      margin = "24px";
      isNiri = cfg.compositor == "niri";
      workspacesModule = if isNiri then "niri/workspaces" else "hyprland/workspaces";
      windowModule = if isNiri then "niri/window" else null;
    in
    {
      programs.waybar = {
        enable = true;

        settings = [
          {
            layer = "top";
            position = "top";
            modules-left = [ workspacesModule ];
            modules-center = lib.optionals (windowModule != null) [ windowModule ];
            modules-right = [
              "tray"
              "pulseaudio"
              "network"
              "battery"
              "clock"
            ];

            "${workspacesModule}" =
              if isNiri then
                {
                  format = "{value}";
                  on-click = "activate";
                }
              else
                {
                  format = "{id} {name}";
                };

            "niri/window" = lib.mkIf isNiri {
              format = "{title}";
              max-length = 50;
              rewrite = {
                "(.*) - Mozilla Firefox" = " $1";
                "(.*) - kitty" = " $1";
              };
            };

            tray = {
              spacing = 10;
            };

            network = {
              interval = 5;
              format-wifi = "  {essid} ({signalStrength}%)";
              format-ethernet = "  {ifname}";
              format-disconnected = "  Offline";
              class = {
                wifi = "wifi";
                ethernet = "ethernet";
                disconnected = "disconnected";
              };
            };

            pulseaudio = {
              format = "{icon} {volume}%";
              format-muted = " Muted ({volume}%)";
              on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
              scroll-step = 5;
              format-icons = [
                ""
                ""
                ""
              ];
            };

            battery = {
              interval = 5;
              states = {
                warning = 25;
                critical = 10;
              };
              format = "{icon} {capacity}%";
              format-charging = " {capacity}%";
              format-plugged = " {capacity}%";
              format-full = "{icon} {capacity}%";
              format-icons = [
                ""
                ""
                ""
                ""
                ""
              ];
              class = {
                charging = "charging";
                full = "full";
                warning = "warning";
                critical = "critical";
              };
            };

            clock = {
              format = "{:%a, %d %b %H:%M}";
              tooltip-format = "{:%Y-%m-%d %H:%M:%S}";
            };
          }
        ];

        style = with config.colorScheme.palette; ''
          * {
            font-family: ${config.custom.features.meta.theme.font.family};
            font-size: ${toString config.custom.features.meta.theme.font.sizes.xlarge}px;
            color: #${base05};
          }

          window#waybar {
            background: #${base00};
            border-bottom: 2px solid #${base0D};
          }

          #workspaces button {
            background: transparent;
            color: #${base05};
            padding: 0 10px;
            margin-right: 4px;
            border-radius: 6px;
            border: 2px solid transparent;
            min-width: 32px;
            min-height: 24px;
            font-weight: bold;
            font-size: ${toString config.custom.features.meta.theme.font.sizes.xlarge}px;
            transition: background 0.2s, color 0.2s, border 0.2s;
          }
          #workspaces button.active {
            background: transparent;
            color: #${base0D};
            border: 2px solid #${base0D};
          }
          #workspaces button.urgent {
            background: #${base08};
            color: #${base00};
          }
          #workspaces button:hover {
            background: #${base0C};
            color: #${base00};
          }

          #window {
            margin-left: ${margin};
            margin-right: ${margin};
            color: #${base05};
          }

          #tray {
            margin-right: ${margin};
          }

          #pulseaudio {
            margin-right: ${margin};
            color: #${base05};
          }
          #pulseaudio.muted {
            color: #${base08};
          }

          #network {
            margin-right: ${margin};
          }
          #network.wifi {
            color: #${base0B};
          }
          #network.ethernet {
            color: #${base0B};
          }
          #network.disconnected {
            color: #${base08};
          }

          #battery {
            margin-right: ${margin};
            color: #${base05};
          }
          #battery.charging {
            color: #${base0D};
          }
          #battery.full {
            color: #${base0B};
          }
          #battery.warning {
            color: #${base0A};
          }
          #battery.critical {
            color: #${base08};
          }

          #clock {
            margin-right: ${margin};
            color: #${base0D};
          }
        '';
      };
    };
}
