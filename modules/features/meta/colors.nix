{ lib, inputs }:
lib.custom.mkFeature {
  path = [
    "meta"
    "colors"
  ];

  # Always set a default colorScheme for apps that need it (nixvim, tmux, etc.)
  homeConfig = _cfg: _: {
    colorScheme = lib.mkDefault inputs.nix-colors.colorSchemes.onedark;
  };
}
