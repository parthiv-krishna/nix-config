{
  pkgs,
  ...
}:
{
  programs.nixvim = {
    config.plugins.nix = {
      enable = true;
    };

    config.plugins.lsp.servers.nixd = {
      enable = true;
      settings = {
        nixpkgs = {
          expr = "import <nixpkgs> { }";
        };
        formatting = {
          command = [ "${pkgs.nixfmt}" ];
        };
        options = {
          nixos = {
            expr = "(builtins.getFlake github:parthiv-krishna/nix-config).nixosConfigurations.*.options";
          };
          home-manager = {
            expr = "(builtins.getFlake github:parthiv-krishna/nix-config).homeConfigurations.*.options";
          };
        };
      };
    };
  };
}
