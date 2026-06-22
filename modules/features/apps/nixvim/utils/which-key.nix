_: {
  programs.nixvim.config = {
    plugins.which-key = {
      enable = true;
      settings.spec = [
        {
          __unkeyed-1 = "<leader>f";
          group = "file search";
        }
        {
          __unkeyed-1 = "<leader>g";
          group = "git operations";
        }
        {
          __unkeyed-1 = "<leader>l";
          group = "lsp actions";
        }
        {
          __unkeyed-1 = "<leader>d";
          group = "diagnostics";
        }
        {
          __unkeyed-1 = "<leader>o";
          group = "opencode";
        }
      ];
    };
  };
}
