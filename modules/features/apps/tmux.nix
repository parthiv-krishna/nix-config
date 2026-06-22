{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "tmux"
  ];

  homeConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      programs.tmux = {
        enable = true;

        keyMode = "vi";
        shortcut = lib.mkDefault "a";
        terminal = "tmux-256color";

        plugins = with pkgs.tmuxPlugins; [
          fuzzback
          resurrect
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-save-interval '15'
            '';
          }
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

          bind ! break-pane
          bind @ set -gqF @move_pane_source "#{pane_id}" \; display-menu -T "Move pane" "Existing window" w "choose-tree -w 'join-pane -s \"#{@move_pane_source}\" -t \"%%\"'" "New session" s "command-prompt -p 'new session name' 'new-session -d -s \"%1\" \; join-pane -s \"#{@move_pane_source}\" -t \"%1:\" \; kill-pane -a -t \"#{@move_pane_source}\" \; switch-client -t \"%1\"'"
          bind D attach-session -c "#{pane_current_path}"
          bind / run-shell -b ${pkgs.tmuxPlugins.fuzzback}/share/tmux-plugins/fuzzback/scripts/fuzzback.sh
          bind ? list-keys -N
          bind f resize-pane -Z

          # mouse
          set-option -g mouse on
          unbind -n MouseDown3Pane

          unbind-key C-a
          bind C-a send-key C-a

          # clipboard passthrough
          set -g set-clipboard on
          set -g allow-passthrough on

          # Avoid leaking Kitty-specific terminal queries into tmux panes.
          set-environment -gu KITTY_INSTALLATION_DIR
          set-environment -gu KITTY_PID
          set-environment -gu KITTY_PUBLIC_KEY
          set-environment -gu KITTY_WINDOW_ID
          set-environment -gu TERMINFO

          # nix-colors theme configuration
          # status bar colors
          set-option -g status-style "fg=#${base05},bg=#${base00}"
          set-option -g status-left-style "fg=#${base0B},bg=#${base01}"
          set-option -g status-right-style "fg=#${base05},bg=#${base01}"
          set-option -g status-right "#{continuum_status} %H:%M %d-%b-%y"

          # window status colors
          set-window-option -g window-status-style "fg=#${base05},bg=#${base00}"
          set-window-option -g window-status-current-style "fg=#${base00},bg=#${base0D}"
          set-window-option -g window-status-activity-style "fg=#${base08},bg=#${base00}"

          # pane border colors
          set-option -g pane-border-style "fg=#${base03}"
          set-option -g pane-active-border-style "fg=#${base0D}"

          # message colors
          set-option -g message-style "fg=#${base05},bg=#${base02}"
          set-option -g message-command-style "fg=#${base05},bg=#${base02}"

          # copy mode colors
          set-window-option -g mode-style "fg=#${base00},bg=#${base0A}"

          # more stable terminal
          set -g default-terminal "screen-256color"
        '';
      };
    };
}
