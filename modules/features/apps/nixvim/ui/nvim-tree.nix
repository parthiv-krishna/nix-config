_: {
  programs.nixvim.config = {
    plugins.nvim-tree = {
      enable = true;
      openOnSetup = false;
      openOnSetupFile = false;
      settings = {
        auto_reload_on_write = true;

        # reclaim Ctrl-K for tmux navigator
        on_attach = {
          __raw = ''
            function(bufnr)
              local function opts(desc)
                return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
              end

              local api = require("nvim-tree.api")
              api.config.mappings.default_on_attach(bufnr)
              vim.keymap.set("n", "<C-K>", ":TmuxNavigateUp<CR>", opts("Refresh"))
            end
          '';
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<Leader>t";
        action = "<cmd>NvimTreeToggle<CR>";
        options.desc = "Toggle file tree";
      }
      {
        mode = "n";
        key = "<Leader>T";
        action = "<cmd>NvimTreeFindFile<CR>";
        options.desc = "Reveal current file in tree";
      }
    ];
  };
}
