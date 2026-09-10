{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "tmux"
  ];

  darwinConfig = _cfg: _: {
    programs.tmux = {
      enable = true;
      # use home-manager tmux config
      extraConfig = ''
        source-file -q ~/.config/tmux/tmux.conf
      '';
    };
  };

  homeConfig =
    _cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      piTmuxResume = pkgs.writeShellApplication {
        name = "pi-tmux-resume";
        runtimeInputs = [
          pkgs.coreutils
          pkgs.jq
          pkgs.tmux
        ];
        text = ''
          # adapted from https://pi.dev/packages/pi-tmux-session-map
          state_dir="''${PI_TMUX_SESSION_MAP_STATE_DIR:-$HOME/.local/state/pi/tmux-sessions}"

          fallback() {
            exec pi --continue
          }

          if [[ -z "''${TMUX:-}" || -z "''${TMUX_PANE:-}" ]]; then
            fallback
          fi

          key="$(tmux display-message -p -t "$TMUX_PANE" '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null || true)"
          if [[ -z "$key" ]]; then
            fallback
          fi

          # keep in sync with pi-tmux-session-map's src/domain/pane-key.ts.
          sanitized="$(printf '%s' "$key" | LC_ALL=C tr -c 'A-Za-z0-9._-' '_' | cut -c 1-120)"
          if [[ -z "$sanitized" || "$sanitized" =~ ^\.+$ ]]; then
            sanitized="pane"
          fi
          hash="$(printf '%s' "$key" | sha256sum | cut -c 1-12)"
          map="$state_dir/$sanitized-$hash.session"

          if [[ -f "$map" ]]; then
            session_file="$(
              jq -er --arg key "$key" '
                select(type == "object" and .schema == 3 and .paneKey == $key)
                | .sessionFile
                | select(type == "string")
              ' "$map" 2>/dev/null || true
            )"
            if [[ "$session_file" == /* && -f "$session_file" ]]; then
              exec pi --session "$session_file"
            fi
          fi

          fallback
        '';
      };
    in
    {
      home.packages = [ piTmuxResume ];

      programs.tmux = {
        enable = true;
        # nix-darwin tmux has some fixes for PATH
        package = if pkgs.stdenv.hostPlatform.isDarwin then null else pkgs.tmux;

        keyMode = "vi";
        shortcut = lib.mkDefault "a";
        terminal = "tmux-256color";

        plugins = with pkgs.tmuxPlugins; [
          fuzzback
          {
            plugin = resurrect;
            extraConfig = ''
              set -g @resurrect-strategy-nvim 'session'
              set -g @resurrect-processes '"pi->${lib.getExe piTmuxResume}"'
            '';
          }
          sensible
          sessionist
          sidebar
          urlview
          vim-tmux-navigator
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-save-interval '1'
              set -g @continuum-restore 'on'
              set -g status-right 'continuum: #{continuum_status} | %H:%M %d-%b-%y'
            '';
          }
        ];

        extraConfig = with config.colorScheme.palette; ''
          bind - split-window -c "#{pane_current_path}"
          bind _ split-window -b -c "#{pane_current_path}"
          bind \\ split-window -h -c "#{pane_current_path}"
          bind | split-window -h -b -c "#{pane_current_path}"
          unbind-key %
          unbind-key \"

          bind ! break-pane
          bind @ set -gqF @move_pane_source "#{pane_id}" \; display-menu -T "Move pane" "Existing window" w "choose-tree -w 'join-pane -s \"#{@move_pane_source}\" -t \"%1\" \; switch-client -t \"#{@move_pane_source}\"'" "New session" s "command-prompt -p 'new session name' 'new-session -d -s \"%1\" \; join-pane -s \"#{@move_pane_source}\" -t \"%1:\" \; kill-pane -a -t \"#{@move_pane_source}\" \; switch-client -t \"#{@move_pane_source}\"'"
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

          # Preserve modified keys used by terminal coding agents.
          set -g extended-keys on
          set -g extended-keys-format csi-u

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
        '';
      };

      custom.features.meta.impermanence.directories = [
        ".tmux/resurrect"
      ];
    };
}
