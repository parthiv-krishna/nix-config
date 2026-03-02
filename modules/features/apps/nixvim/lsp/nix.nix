{
  pkgs,
  ...
}:
{
  programs.nixvim = {
    plugins.nix = {
      enable = true;
    };

    plugins.lsp.servers.nixd = {
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
