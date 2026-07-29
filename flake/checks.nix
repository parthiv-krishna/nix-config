# pre-commit checks
# adapted from https://github.com/EmergentMind/nix-config/blob/dev/checks.nix

{
  inputs,
  lib,
  pkgs,
  system,
  ...
}:
let
  inherit (import ../constants.nix) hosts;
  systemBuilds = lib.mapAttrs' (
    hostName: _hostConfig:
    lib.nameValuePair "build-${hostName}" (
      if lib.hasSuffix "-darwin" system then
        inputs.self.darwinConfigurations.${hostName}.system
      else
        inputs.self.nixosConfigurations.${hostName}.config.system.build.toplevel
    )
  ) (lib.filterAttrs (_: hostConfig: hostConfig.system == system) hosts);
in
{

  pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
    src = ./.;
    default_stages = [ "pre-commit" ];
    package = pkgs.prek;
    hooks = {
      # general stuff
      check-added-large-files = {
        enable = true;
        excludes = [
          "\\.png"
          "\\.jpg"
        ];
      };
      check-case-conflicts.enable = true;
      check-merge-conflicts.enable = true;
      detect-private-keys.enable = true;
      end-of-file-fixer.enable = true;
      fix-byte-order-marker.enable = true;
      mixed-line-endings.enable = true;
      trim-trailing-whitespace.enable = true;

      # nix formatting
      deadnix.enable = true;
      nixfmt.enable = true;
      statix.enable = true;

      # other formatting
      black.enable = true;
      shellcheck.enable = true;
      shfmt.enable = true;
      yamlfmt.enable = true;
    };
  };
}
// systemBuilds
