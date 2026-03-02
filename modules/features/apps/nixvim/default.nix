{ lib }:
let
  optionPath = [ "custom" "features" "apps" "nixvim" ];
  
  setAttrByPath = path: value:
    lib.foldr (name: acc: { ${name} = acc; }) value path;

  getAttrByPath = path: attrs:
    lib.foldl (acc: name: acc.${name}) attrs path;

  optionsDef = {
    enable = lib.mkEnableOption "the apps.nixvim feature";
  };

  homeModule = { config, lib, ... }:
    let
      cfg = getAttrByPath optionPath config;
    in
    {
      imports = lib.custom.scanPaths ./.;

      options = setAttrByPath optionPath optionsDef;

      config = lib.mkIf cfg.enable {
        programs.nixvim.config = {
          enable = true;

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
              key = "<Leader>n";
              action = ":noh<CR>";
            }
            # vertical split
            {
              key = "<Leader>v";
              action = ":vs<CR>";
            }
            # horizontal split
            {
              key = "<Leader>h";
              action = ":sv<CR>";
            }
          ];

        };
      };
    };
in
{
  nixos = _:
    {
      options = setAttrByPath optionPath optionsDef;

      config = {
        home-manager.sharedModules = [ homeModule ];
      };
    };

  home = homeModule;
}
