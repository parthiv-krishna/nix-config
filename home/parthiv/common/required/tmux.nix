# tmux configuration, should be imported to home-manager

{ lib, pkgs, ... }:
{
  programs.tmux = {
    enable = true;

    keyMode = "vi";
    shortcut = lib.mkDefault "a";

    plugins = with pkgs.tmuxPlugins; [
      fuzzback
      onedark-theme
      resurrect
      sensible
      sessionist
      sidebar
      urlview
      vim-tmux-navigator
    ];

    extraConfig = ''
      bind - split-window -c "#{pane_current_path}"
      bind _ split-window -b -c "#{pane_current_path}"
      bind \\ split-window -h -c "#{pane_current_path}"
      bind | split-window -h -b -c "#{pane_current_path}"
      unbind-key %
      unbind-key \"

      unbind-key C-a
      bind C-a send-key C-a
    '';
  };
}
