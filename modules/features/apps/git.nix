{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "git"
  ];

  homeConfig = _cfg: _: {
    programs = {
      git = {
        enable = true;
        lfs.enable = true;

        settings = {
          alias = {
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
            # shortcuts for github
            "git@github.com:" = {
              insteadOf = "gh:";
            };
            "https://github.com/" = {
              insteadOf = "gh/";
            };
          };

          user = {
            name = "Parthiv Krishna";
            email = "parthiv-krishna@users.noreply.github.com";
          };
        };

        ignores = [
          # vim stuff
          "*~"
          "*.swp"
        ];
      };

      # difftastic for smarter diffs
      difftastic = {
        enable = true;
        git.enable = true;
      };

      # github cli
      gh = {
        enable = true;
        settings = {
          git_protocol = "ssh";
        };
      };
    };
  };
}
