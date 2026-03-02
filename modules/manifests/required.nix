{ config, lib, ... }:
{
  options.custom.manifests.required.enable = lib.mkEnableOption "required core features";

  config = lib.mkIf config.custom.manifests.required.enable {
    custom.features = {
      apps = {
        git.enable = lib.mkDefault true;
        bash.enable = lib.mkDefault true;
        tmux.enable = lib.mkDefault true;
        nixvim.enable = lib.mkDefault true;
        cli-utils.enable = lib.mkDefault true;
      };

      networking.tailscale.enable = lib.mkDefault true;

      meta = {
        colors.enable = lib.mkDefault true;
        sops.enable = lib.mkDefault true;
        impermanence.enable = lib.mkDefault true;
        auto-upgrade.enable = lib.mkDefault true;
        parthiv.enable = lib.mkDefault true;
        restic.enable = lib.mkDefault true;
        unfree.enable = lib.mkDefault true;
        discord-notifiers.enable = lib.mkDefault true;
      };
    };
  };
}
