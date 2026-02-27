# Tmux configuration feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "tmux" ];

  homeConfig = cfg: { config, lib, pkgs, ... }: {
    programs.tmux = {
      enable = true;

      keyMode = "vi";
      shortcut = lib.mkDefault "a";

      plugins = with pkgs.tmuxPlugins; [
        fuzzback
        resurrect
        sensible
        sessionist
        sidebar
        urlview
        vim-tmux-navigator
      ];

      extraConfig = with config.colorScheme.palette; ''
        bind - split-window -c "#{pane_current_path}"
        bind _ split-window -b -c "#{pane_current_path}"
        bind \\ split-window -h -c "#{pane_current_path}"
        bind | split-window -h -b -c "#{pane_current_path}"
        unbind-key %
        unbind-key \"

        bind @ choose-window 'join-pane -h -s "%%"'

        # mouse
        set-option -g mouse on
        unbind -n MouseDown3Pane

        unbind-key C-a
        bind C-a send-key C-a

        # nix-colors theme configuration
        # Status bar colors
        set-option -g status-style "fg=#${base05},bg=#${base00}"
        set-option -g status-left-style "fg=#${base0B},bg=#${base01}"
        set-option -g status-right-style "fg=#${base05},bg=#${base01}"

        # Window status colors
        set-window-option -g window-status-style "fg=#${base05},bg=#${base00}"
        set-window-option -g window-status-current-style "fg=#${base00},bg=#${base0D}"
        set-window-option -g window-status-activity-style "fg=#${base08},bg=#${base00}"

        # Pane border colors
        set-option -g pane-border-style "fg=#${base03}"
        set-option -g pane-active-border-style "fg=#${base0D}"

        # Message colors
        set-option -g message-style "fg=#${base05},bg=#${base02}"
        set-option -g message-command-style "fg=#${base05},bg=#${base02}"

        # Copy mode colors
        set-window-option -g mode-style "fg=#${base00},bg=#${base0A}"
      '';
    };
  };
}
