{ config, lib, ... }:
{
  options.custom.manifests.required.enable = lib.mkEnableOption "required core features";

  config = lib.mkIf config.custom.manifests.required.enable {
    custom.features = {
      # Core apps
      apps.git.enable = lib.mkDefault true;
      apps.bash.enable = lib.mkDefault true;
      apps.tmux.enable = lib.mkDefault true;
      apps.nixvim.enable = lib.mkDefault true;

      # Meta/system features
      networking.tailscale.enable = lib.mkDefault true;
      meta.sops.enable = lib.mkDefault true;
      meta.impermanence.enable = lib.mkDefault true;
      meta.auto-upgrade.enable = lib.mkDefault true;
      meta.parthiv.enable = lib.mkDefault true;
      meta.restic.enable = lib.mkDefault true;
      meta.unfree.enable = lib.mkDefault true;
      # Note: constants is a plain module (always loaded), not a feature
      meta.discord-notifiers.enable = lib.mkDefault true;
    };
  };
}
