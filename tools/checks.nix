# pre-commit checks
# adapted from https://github.com/EmergentMind/nix-config/blob/dev/checks.nix

{
  inputs,
  pkgs,
  system,
  ...
}:
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
