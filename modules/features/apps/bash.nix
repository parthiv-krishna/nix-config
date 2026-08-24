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

        shellAliases = lib.optionalAttrs pkgs.stdenv.isLinux {
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
