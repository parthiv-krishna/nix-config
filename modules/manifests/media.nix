{ config, lib, ... }:
{
  options.custom.manifests.media.enable = lib.mkEnableOption "media server features";

  config = lib.mkIf config.custom.manifests.media.enable {
    custom.features.selfhosted = {
      media-base.enable = lib.mkDefault true;
      bazarr.enable = lib.mkDefault true;
      jellyfin.enable = lib.mkDefault true;
      jellyseerr.enable = lib.mkDefault true; # OIDC version at request.sub0.net
      seerr.enable = lib.mkDefault true; # New version at request2.sub0.net (testing)
      prowlarr.enable = lib.mkDefault true;
      radarr.enable = lib.mkDefault true;
      sonarr.enable = lib.mkDefault true;
      transmission.enable = lib.mkDefault true;
      unmanic.enable = lib.mkDefault true;
    };
  };
}
