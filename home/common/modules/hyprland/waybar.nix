{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.hyprland;
  # One Dark color palette
  onedark = {
    bg = "#282c34";
    fg = "#abb2bf";
    blue = "#61afef";
    green = "#98c379";
    yellow = "#e5c07b";
    red = "#e06c75";
    cyan = "#56b6c2";
  };
  margin = "12px";
in
lib.mkIf cfg.enable {
  home.packages = with pkgs; [
    hyprland-autoname-workspaces
  ];

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
          format = "{name}";
        };

        network = {
          interval = 5;
          format-wifi = "";
          format-ethernet = "";
          format-disconnected = "";
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

    style = ''
      * {
        font-size: 13px;
        color: ${onedark.fg};
      }

      window#waybar {
        background: ${onedark.bg};
        border-bottom: 2px solid ${onedark.blue};
      }

      #workspaces button {
        background: transparent;
        color: ${onedark.fg};
        padding: 0 10px;
        margin-right: 4px;
        border-radius: 6px;
        min-width: 32px;
        min-height: 24px;
        font-weight: bold;
        font-size: 14px;
        transition: background 0.2s, color 0.2s;
      }
      #workspaces button.active {
        background: ${onedark.blue};
        color: ${onedark.bg};
      }
      #workspaces button.urgent {
        background: ${onedark.red};
        color: ${onedark.bg};
      }
      #workspaces button:hover {
        background: ${onedark.cyan};
        color: ${onedark.bg};
      }

      #network {
        margin-right: ${margin};
      }
      #network.wifi {
        color: ${onedark.green};
      }
      #network.ethernet {
        color: ${onedark.green};
      }
      #network.disconnected {
        color: ${onedark.red};
      }

      #battery {
        margin-right: ${margin};
        color: ${onedark.fg};
      }
      #battery.charging {
        color: ${onedark.blue};
      }
      #battery.full {
        color: ${onedark.green};
      }
      #battery.warning {
        color: ${onedark.yellow};
      }
      #battery.critical {
        color: ${onedark.red};
      }

      #clock {
        margin-right: ${margin};
        color: ${onedark.blue};
      }
    '';
  };
}
