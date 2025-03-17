# git configuration, should be imported to home-manager

{ ... }:
{
  programs.git = {
    enable = true;
    lfs.enable = true;

    userName = "Parthiv Krishna";
    userEmail = "parthiv-krishna@users.noreply.github.com";

    # use difftastic syntax highlighter
    difftastic.enable = true;

    extraConfig = {
      apply = {
        whitespace = "fix";
      };

      core = {
        # error on trailing whitespace
        whitespace = "trailing-space,space-before-tab";
      };

      init = {
        defaultBranch = "main";
      };

      url = {
        # shortcutes for github
        "git@github.com:" = {
          insteadOf = "gh:";
        };
        "https://github.com/" = {
          insteadOf = "gh/";
        };
      };
    };

    aliases = {
      a = "add";
      ap = "add -p";
      au = "add -u";

      b = "branch";
      bv = "branch -v";

      bs = "bisect";
      bsb = "bisect bad";
      bsg = "bisect good";

      c = "commit";
      ca = "commit --amend --no-edit";
      cam = "commit --amend -m";
      cm = "commit -m";

      co = "checkout";
      cob = "checkout -b";

      d = "diff";
      dc = "diff --check";
      dn = "diff --no-index";
      dnw = "diff --no-index --word-diff";
      ds = "diff --staged";
      dsc = "diff --staged --check";
      dsw = "diff --staged --word-diff";
      dw = "diff --word-diff";

      r = "reset";

      s = "status";
      su = "status -uno";
    };

    ignores = [
      # vim stuff
      "*~"
      "*.swp"
    ];
  };
}
