{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "nixvim"
  ];

  extraOptions = {
    newSplitCommand = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = "Command to run after creating a new Neovim split.";
    };
  };

  homeImports = lib.custom.scanPaths ./.;

  homeConfig =
    cfg:
    { config, pkgs, ... }:
    {
      programs.nixvim = {
        config = {
          nixpkgs.source = pkgs.path;

          enable = true;

          extraPlugins = [
            pkgs.vimPlugins.vim-obsession
          ];

          autoCmd = [
            {
              event = "VimEnter";
              callback = {
                __raw = ''
                  function()
                    if vim.v.this_session == "" and vim.fn.argc() == 0 then
                      if vim.fn.filereadable("Session.vim") == 1 then
                        vim.cmd("source Session.vim")
                      else
                        vim.cmd("Obsess")
                      end
                    end
                  end
                '';
              };
            }
          ];

          viAlias = true;
          vimAlias = true;
          defaultEditor = true;

          opts = {
            # line numbers
            number = true;
            relativenumber = true;

            # search
            hlsearch = true;
            incsearch = true;
            ignorecase = true;
            showmatch = true;
            smartcase = true;

            # whitespace
            expandtab = true;
            shiftwidth = 2;
            tabstop = 2;
            smartindent = true;

            # persistent undo
            undofile = true;

            # auto reload files changed on disk
            autoread = true;
          };

          colorschemes = {
            # Use base16 colorscheme with nix-colors
            base16 = {
              enable = true;
              colorscheme = config.colorScheme.slug;
            };
          };

          globals = {
            mapleader = " ";
          };

          keymaps = [
            # swap gj/j and gk/k
            {
              key = "j";
              action = "gj";
              mode = "n";
            }
            {
              key = "k";
              action = "gk";
              mode = "n";
            }
            {
              key = "gj";
              action = "j";
              mode = "n";
            }
            {
              key = "gk";
              action = "k";
              mode = "n";
            }
            # swap g<down>/<down> and g<up>/<up>
            {
              key = "<down>";
              action = "g<down>";
            }
            {
              key = "<up>";
              action = "g<up>";
            }
            {
              key = "g<up>";
              action = "<up>";
            }
            {
              key = "g<down>";
              action = "<down>";
            }
            # remove search highlight
            {
              key = "<Esc>";
              action = "<cmd>noh<CR>";
              mode = "n";
            }
            # vertical splits with Telescope file selection
            {
              key = "<Leader>\\";
              action = "<cmd>rightbelow vsplit<CR>${cfg.newSplitCommand}";
              options.desc = "Split right";
            }
            {
              key = "<Leader>|";
              action = "<cmd>leftabove vsplit<CR>${cfg.newSplitCommand}";
              options.desc = "Split left";
            }
            # horizontal splits with Telescope file selection
            {
              key = "<Leader>-";
              action = "<cmd>belowright split<CR>${cfg.newSplitCommand}";
              options.desc = "Split below";
            }
            {
              key = "<Leader>_";
              action = "<cmd>aboveleft split<CR>${cfg.newSplitCommand}";
              options.desc = "Split above";
            }
          ];
        };
      };
    };
}
