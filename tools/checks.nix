# pre-commit checks
# adapted from https://github.com/EmergentMind/nix-config/blob/dev/checks.nix

{
  inputs,
  system,
  ...
}:
{

  pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
    src = ./.;
    default_stages = [ "pre-commit" ];
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
      nixfmt-rfc-style.enable = true;
      statix = {
        enable = true;
        # don't bother "fixing" auto-generated hardware-configuration.nix
        settings.ignore = [ "hardware-configuration.nix" ];
      };

      # bash formatting
      shellcheck.enable = true;
      shfmt.enable = true;

    };
  };
}
