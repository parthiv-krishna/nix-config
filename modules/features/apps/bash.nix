{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "bash"
  ];

  darwinConfig =
    _cfg:
    { config, pkgs, ... }:
    lib.mkIf (config.system.primaryUser != null) {
      programs.bash.enable = true;
      environment.shells = [ pkgs.bashInteractive ];
      users.users.${config.system.primaryUser}.shell = lib.mkDefault pkgs.bashInteractive;
    };

  homeConfig =
    _cfg:
    { lib, pkgs, ... }:
    {
      programs.bash = {
        enable = true;

        enableCompletion = true;

        initExtra = ''
          # match the default nixos bash prompt
          if [ "$TERM" != "dumb" ]; then
            PROMPT_COLOR="1;31m"
            ((UID)) && PROMPT_COLOR="1;32m"
            PS1="\n\[\033[$PROMPT_COLOR\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\\$\[\033[0m\] "
            if [ "$TERM" = "xterm" ]; then
              PS1="\[\033]2;\h:\u:\w\007\]$PS1"
            fi
          fi

          # vi mode input
          bind 'set editing-mode vi'
          bind 'set vi-cmd-mode-string "\1\e[3 q\2"'
          bind 'set vi-ins-mode-string "\1\e[6 q\2"'
          bind 'set show-mode-in-prompt on'

          # include .bashrc-extra if it exists
          # for machine-specific config that won't be checked in
          [[ -f ~/.bashrc-extra ]] && . ~/.bashrc-extra

          # print system info
          ${pkgs.fastfetch}/bin/fastfetch
        '';

        shellAliases = lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
          open = "xdg-open";
        };

        shellOptions = [
          "autocd"
          "cdable_vars"
          "cdspell"
          "dirspell"
          "globstar"
          "histverify"
        ];
      };
    };
}
