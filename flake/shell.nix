# Development environment for nix-config
# adapted from https://github.com/EmergentMind/nix-config/blob/dev/shell.nix

{
  checks,
  pkgs,
  ...
}:
{
  # CI update tools, without the interactive shell's pre-commit hooks.
  update = pkgs.mkShellNoCC {
    packages = with pkgs; [
      bash
      coreutils
      curl
      git
      gnugrep
      gnused
      gnutar
      gzip
      nix
      openssh
    ];
  };

  default = pkgs.mkShell {
    NIX_CONFIG = "extra-experimental-features = nix-command flakes";

    inherit (checks.pre-commit-check) shellHook;
    buildInputs = checks.pre-commit-check.enabledPackages;

    nativeBuildInputs = builtins.attrValues {
      inherit (pkgs)

        age
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
