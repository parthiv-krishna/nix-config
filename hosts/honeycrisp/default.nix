# Configuration for honeycrisp (Apple Silicon Mac)
{
  networking.hostName = "honeycrisp";

  custom = {
    manifests.required.enable = true;

    features = {
      apps.opencode.enable = true;

      # These required-manifest defaults assume a persistent NixOS root.
      meta = {
        impermanence.enable = false;
        sops.enable = false;
      };
    };
  };

  # This controls nix-darwin compatibility and should only change deliberately.
  system.stateVersion = 6;
}
