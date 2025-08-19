_: {
  programs.nixvim.plugins.nvim-tree = {
    enable = true;
    openOnSetup = true;
    openOnSetupFile = true;
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

}
