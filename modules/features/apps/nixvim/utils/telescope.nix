_: {
  custom.features.apps.nixvim.newSplitCommand = "<cmd>Telescope find_files<CR>";

  programs.nixvim.config = {
    plugins.telescope = {
      enable = true;
    };

    keymaps = [
      {
        mode = "n";
        key = "<Leader>ff";
        action = "<cmd>Telescope find_files<CR>";
        options.desc = "Find project files";
      }
      {
        mode = "n";
        key = "<Leader>fd";
        action = "<cmd>lua require('telescope.builtin').find_files({ cwd = vim.fn.expand('%:p:h') })<CR>";
        options.desc = "Find files beside current file";
      }
      {
        mode = "n";
        key = "<Leader>fg";
        action = "<cmd>Telescope live_grep<CR>";
        options.desc = "Live grep";
      }
      {
        mode = "n";
        key = "<Leader>fb";
        action = "<cmd>Telescope buffers<CR>";
        options.desc = "Find buffers";
      }
      {
        mode = "n";
        key = "<Leader>fr";
        action = "<cmd>Telescope oldfiles<CR>";
        options.desc = "Recent files";
      }
    ];

    autoCmd = [
      {
        event = "User";
        pattern = "NixvimSessionNew";
        callback = {
          __raw = ''
            function()
              vim.schedule(function()
                require("telescope.builtin").find_files()
              end)
            end
          '';
        };
      }
    ];
  };
}
