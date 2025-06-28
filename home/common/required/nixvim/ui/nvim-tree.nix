_: {
  programs.nixvim.plugins.nvim-tree = {
    enable = true;
    openOnSetup = true;
    openOnSetupFile = true;
    autoReloadOnWrite = true;

    # reclaim Ctrl-K for tmux navigator
    onAttach = {
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

}
