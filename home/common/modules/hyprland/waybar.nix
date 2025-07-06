{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.hyprland;
  margin = "12px";
in
lib.mkIf cfg.enable {
  programs.waybar = {
    enable = true;

    settings = [
      {
        layer = "top";
        position = "top";
        modules-left = [ "hyprland/workspaces" ];
        modules-center = [ ];
        modules-right = [
          "network"
          "battery"
          "clock"
        ];

        "hyprland/workspaces" = {
          format = "{id} {name}";
        };

        network = {
          interval = 5;
          format-wifi = "";
          format-ethernet = "";
          format-disconnected = "";
          class = {
            wifi = "wifi";
            ethernet = "ethernet";
            disconnected = "disconnected";
          };
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
            ""
            ""
            ""
            ""
            ""
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
        font-family: ${config.custom.font.family};
        font-size: ${toString config.custom.font.sizes.xlarge}px;
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
        font-size: ${toString config.custom.font.sizes.xlarge}px;
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

  wayland.windowManager.hyprland.settings.exec-once = [
    "waybar"
  ];
}
