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
  systemd.services = {
    nix-gc-after-upgrade = {
      description = "Nix garbage collection after auto-upgrade";
      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = "${pkgs.nix}/bin/nix-collect-garbage --delete-older-than 10d";
      };
    };

    # trigger garbage collection after successful upgrade
    nixos-upgrade = {
      onSuccess = [ "nix-gc-after-upgrade.service" ];
    };
  };

  # discord notifications
  custom.discord-notifiers = {
    nixos-upgrade.enable = true;
    nix-gc-after-upgrade.enable = true;
  };

  # make ssh key accessible to auto upgrade service
  systemd.tmpfiles.rules = [
    "L /root/.ssh/id_ed25519 - - - - ${config.users.users.parthiv.home}/.ssh/id_ed25519"
  ];

}
