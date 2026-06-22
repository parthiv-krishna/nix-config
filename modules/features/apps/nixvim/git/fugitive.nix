_: {
  programs.nixvim.config = {
    plugins.fugitive = {
      enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<Leader>gs";
        action = "<cmd>Git<CR>";
        options.desc = "Git status";
      }
      {
        mode = "n";
        key = "<Leader>gc";
        action = "<cmd>Git commit<CR>";
        options.desc = "Git commit";
      }
      {
        mode = "n";
        key = "<Leader>gp";
        action = "<cmd>Git push<CR>";
        options.desc = "Git push";
      }
      {
        mode = "n";
        key = "<Leader>gP";
        action = "<cmd>Git pull<CR>";
        options.desc = "Git pull";
      }
      {
        mode = "n";
        key = "<Leader>gb";
        action = "<cmd>Git blame<CR>";
        options.desc = "Git blame";
      }
      {
        mode = "n";
        key = "<Leader>gd";
        action = "<cmd>Gdiffsplit<CR>";
        options.desc = "Git diff current file";
      }
      {
        mode = "n";
        key = "<Leader>gl";
        action = "<cmd>Git log --oneline --decorate --graph --all<CR>";
        options.desc = "Git log graph";
      }
    ];
  };
}
