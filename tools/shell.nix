# Development environment for nix-config
# adapted from https://github.com/EmergentMind/nix-config/blob/dev/shell.nix

{
  checks,
  pkgs,
  ...
}:
{
  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";

    inherit (checks.pre-commit-check) shellHook;
    buildInputs = checks.pre-commit-check.enabledPackages;

    nativeBuildInputs = builtins.attrValues {
      inherit (pkgs)

        age
        colmena
        compose2nix
        git
        nix
        sops
        pre-commit
        ssh-to-age
        ;
    };
  };
}
