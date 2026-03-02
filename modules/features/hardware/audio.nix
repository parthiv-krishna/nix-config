{ lib }:
lib.custom.mkFeature {
  path = [ "hardware" "audio" ];

  extraOptions = {
    micVolume = lib.mkOption {
      type = lib.types.float;
      default = 1.0;
      description = "Default microphone volume";
    };
  };

  systemConfig = cfg: { ... }: {
    services.pipewire.wireplumber.extraConfig = {
      "10-default-volume" = {
        "wireplumber.settings" = {
          "device.routes.default-source-volume" = cfg.micVolume;
        };
      };
    };
  };
}
