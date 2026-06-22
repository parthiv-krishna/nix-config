_: {
  programs.nixvim.config.plugins.lsp.servers.pyright = {
    enable = true;
    settings = {
      python = {
        analysis = {
          typeCheckingMode = "basic";
          autoSearchPaths = true;
          useLibraryCodeForTypes = true;
        };
      };
    };
  };
}
