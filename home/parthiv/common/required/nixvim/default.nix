{
  helpers,
  inputs,
  lib,
  ...
}:
{

  imports = lib.flatten [
    inputs.nixvim.homeManagerModules.nixvim
    (helpers.scanPaths ./.)
  ];

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
    };

    colorschemes = {
      one.enable = true;
    };

    globals = {
      mapleader = "\\";
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
}
