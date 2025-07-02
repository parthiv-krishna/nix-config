{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.hyprland;
in
lib.mkIf cfg.enable {
  programs.wofi = {
    enable = true;

    settings = {
      width = 600;
      height = 400;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 40;
      gtk_dark = true;
    };

    style = with config.colorScheme.palette; ''
      window {
        margin: 0px;
        border: 2px solid #${base0D};
        border-radius: 12px;
        background-color: #${base00};
        font-family: monospace;
        font-size: 14px;
        font-weight: 500;
      }

      #input {
        margin: 5px;
        border: 2px solid #${base02};
        border-radius: 8px;
        color: #${base05};
        background-color: #${base01};
        padding: 8px 12px;
        font-size: 16px;
        box-shadow: 0 2px 4px rgba(0, 0, 0, 0.2);
      }

      #input:focus {
        border-color: #${base0D};
      }

      #input image {
        color: #${base0D};
      }

      #inner-box {
        margin: 5px;
        border: none;
        background-color: #${base00};
      }

      #outer-box {
        margin: 5px;
        border: none;
        background-color: #${base00};
      }

      #scroll {
        margin: 0px;
        border: none;
        background-color: #${base00};
      }

      #text {
        margin: 5px;
        border: none;
        color: #${base05};
        font-weight: 500;
      }

      #entry {
        border-radius: 6px;
        margin: 2px;
        padding: 8px;
        background-color: transparent;
        transition: all 0.2s ease;
      }

      #entry:selected {
        background-color: #${base0D};
        color: #${base00};
        font-weight: bold;
      }

      #entry:hover {
        background-color: #${base02};
      }

      #entry:selected #text {
        color: #${base00};
      }

      #entry img {
        margin-right: 8px;
      }
    '';
  };
}
