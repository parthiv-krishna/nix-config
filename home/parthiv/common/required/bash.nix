# bash configuration, should be imported to home-manager

_: {
  programs.bash = {
    enable = true;

    enableCompletion = true;

    initExtra = ''
      # vi mode input
      bind 'set editing-mode vi'
      bind 'set vi-cmd-mode-string "\1\e[3 q\2"'
      bind 'set vi-ins-mode-string "\1\e[6 q\2"'
      bind 'set show-mode-in-prompt on'

      # print system info
      fastfetch
    '';

    shellAliases = {
      open = "xdg-open";
      rm = "echo \"rm is disabled, please use trash\"";
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
}
