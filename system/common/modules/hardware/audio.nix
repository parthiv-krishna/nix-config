{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.audio;
in
{
  options.custom.audio = {
    enable = lib.mkEnableOption "Audio support";

    micVolume = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Default microphone volume";
    };
  };

  config = lib.mkIf cfg.enable {
    services.pipewire.wireplumber.extraConfig = {
      "10-default-volume" = {
        "wireplumber.settings" = {
          "device.routes.default-source-volume" = cfg.micVolume;
        };
      };
    };
  };
}
