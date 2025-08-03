{
  config,
  pkgs,
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

  # garbage collection after auto-upgrade
  systemd.services.nix-gc-after-upgrade = {
    description = "Nix garbage collection after auto-upgrade";
    serviceConfig = {
      Type = "oneshot";
      User = "root";
      ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 10d";
    };
  };

  # trigger garbage collection after successful upgrade
  systemd.services.nixos-upgrade = {
    onSuccess = [ "nix-gc-after-upgrade.service" ];
  };

  # discord notifications
  custom.discord-notifiers = {
    nixos-upgrade.enable = true;
    nix-gc-after-upgrade.enable = true;
  };
}
