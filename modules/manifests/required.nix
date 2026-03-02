{ config, lib, ... }:
{
  options.custom.manifests.required.enable = lib.mkEnableOption "required core features";

  config = lib.mkIf config.custom.manifests.required.enable {
    custom.features = {
      apps.git.enable = lib.mkDefault true;
      apps.bash.enable = lib.mkDefault true;
      apps.tmux.enable = lib.mkDefault true;
      apps.nixvim.enable = lib.mkDefault true;

      networking.tailscale.enable = lib.mkDefault true;
      meta.sops.enable = lib.mkDefault true;
      meta.impermanence.enable = lib.mkDefault true;
      meta.auto-upgrade.enable = lib.mkDefault true;
      meta.parthiv.enable = lib.mkDefault true;
      meta.restic.enable = lib.mkDefault true;
      meta.unfree.enable = lib.mkDefault true;

      meta.discord-notifiers.enable = lib.mkDefault true;
    };
  };
}
