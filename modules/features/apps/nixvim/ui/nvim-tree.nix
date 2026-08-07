_: {
  programs.nixvim.config = {
    # persist nvim-tree visibility in sessions
    extraConfigLua = ''
      vim.opt.sessionoptions:append("globals")

      if vim.g.NvimTreeSessionOpen == nil then
        vim.g.NvimTreeSessionOpen = 0
      end

      local nvim_tree_api = require("nvim-tree.api")
      nvim_tree_api.events.subscribe(nvim_tree_api.events.Event.TreeOpen, function()
        vim.g.NvimTreeSessionOpen = 1
      end)
      nvim_tree_api.events.subscribe(nvim_tree_api.events.Event.TreeClose, function()
        vim.g.NvimTreeSessionOpen = 0
      end)

      vim.api.nvim_create_autocmd("SessionLoadPost", {
        callback = function()
          if vim.g.NvimTreeSessionOpen == 1 then
            vim.schedule(nvim_tree_api.tree.open)
          end
        end,
      })
    '';

    plugins.nvim-tree = {
      enable = true;
      openOnSetup = false;
      openOnSetupFile = false;
      settings = {
        auto_reload_on_write = true;

        # keybinds
        on_attach = {
          __raw = ''
            function(bufnr)
              local function opts(desc)
                return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
              end

              local api = require("nvim-tree.api")
              api.config.mappings.default_on_attach(bufnr)
              vim.keymap.set("n", "<C-[>", api.tree.change_root_to_parent, opts("Up"))
              -- reclaim C-K for tmux navigator
              vim.keymap.set("n", "<C-K>", ":TmuxNavigateUp<CR>", opts("Refresh"))
            end
          '';
        };
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<Leader>tt";
        action = "<cmd>NvimTreeToggle<CR>";
        options.desc = "Toggle file tree";
      }
      {
        mode = "n";
        key = "<Leader>tf";
        action = "<cmd>NvimTreeFindFile<CR>";
        options.desc = "Reveal current file in tree";
      }
    ];
  };
}
