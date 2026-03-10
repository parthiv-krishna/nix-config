{ config, lib, ... }:
{
  options.custom.manifests.required.enable = lib.mkEnableOption "required core features";

  config = lib.mkIf config.custom.manifests.required.enable {
    custom.features = {
      apps = {
        bash.enable = lib.mkDefault true;
        btop.enable = lib.mkDefault true;
        curl.enable = lib.mkDefault true;
        dig.enable = lib.mkDefault true;
        fastfetch.enable = lib.mkDefault true;
        fzf.enable = lib.mkDefault true;
        git.enable = lib.mkDefault true;
        nixvim.enable = lib.mkDefault true;
        ripgrep.enable = lib.mkDefault true;
        tmux.enable = lib.mkDefault true;
        trash-cli.enable = lib.mkDefault true;
        unzip.enable = lib.mkDefault true;
        wget.enable = lib.mkDefault true;
        yazi.enable = lib.mkDefault true;
        zip.enable = lib.mkDefault true;
      };

      networking.tailscale.enable = lib.mkDefault true;

      meta = {
        auto-upgrade.enable = lib.mkDefault true;
        theme.enable = lib.mkDefault true;
        discord-notifiers.enable = lib.mkDefault true;
        impermanence.enable = lib.mkDefault true;
        nix.enable = lib.mkDefault true;
        parthiv.enable = lib.mkDefault true;
        sops.enable = lib.mkDefault true;
        unfree.enable = lib.mkDefault true;
      };

      storage = {
        restic.enable = lib.mkDefault true;
      };
    };
  };
}
