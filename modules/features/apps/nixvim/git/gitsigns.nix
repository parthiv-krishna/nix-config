_: {
  programs.nixvim.config = {
    plugins.gitsigns = {
      enable = true;
      settings = {
        current_line_blame = true;
      };
    };

    keymaps = [
      {
        mode = "n";
        key = "<Leader>gj";
        action = "<cmd>lua require('gitsigns').nav_hunk('next', { target = 'all' })<CR>";
        options.desc = "Next git hunk";
      }
      {
        mode = "n";
        key = "<Leader>gk";
        action = "<cmd>lua require('gitsigns').nav_hunk('prev', { target = 'all' })<CR>";
        options.desc = "Previous git hunk";
      }
      {
        mode = "n";
        key = "<Leader>gh";
        action = "<cmd>Gitsigns preview_hunk<CR>";
        options.desc = "Preview git hunk";
      }
      {
        mode = "n";
        key = "<Leader>ga";
        action = "<cmd>Gitsigns stage_hunk<CR>";
        options.desc = "Stage/unstage git hunk";
      }
      {
        mode = "n";
        key = "<Leader>gu";
        action = "<cmd>Gitsigns reset_hunk<CR>";
        options.desc = "Undo git hunk";
      }
      {
        mode = "n";
        key = "<Leader>gr";
        action = "<cmd>Gitsigns stage_hunk<CR>";
        options.desc = "Reset/unstage git hunk";
      }
      {
        mode = "n";
        key = "<Leader>gA";
        action = "<cmd>Gitsigns stage_buffer<CR>";
        options.desc = "Stage current buffer";
      }
      {
        mode = "n";
        key = "<Leader>gR";
        action = "<cmd>Gitsigns reset_buffer_index<CR>";
        options.desc = "Reset/unstage current buffer";
      }
      {
        mode = "n";
        key = "<Leader>gB";
        action = "<cmd>Gitsigns blame_line<CR>";
        options.desc = "Blame current line";
      }
    ];
  };
}
