{
  config,
  ...
}:
{
  system.autoUpgrade = {
    enable = true;
    flake = "github:parthiv-krishna/nix-config#${config.networking.hostName}";
    flags = [
      "-L"
    ];
    dates = "Tue 02:00";
    randomizedDelaySec = "45min";
    persistent = true;
  };
}
