# ZFS automation feature - system-only
{ lib }:
lib.custom.mkFeature {
  path = [ "storage" "zfs" ];

  systemConfig = cfg: { config, lib, ... }: {
    services.zfs = {
      autoScrub = {
        enable = true;
        interval = "monthly";
      };

      autoSnapshot = {
        enable = true;
        frequent = 4;
        hourly = 24;
        daily = 7;
        weekly = 4;
        monthly = 12;
      };

      trim = {
        enable = true;
        interval = "weekly";
      };
    };

    custom.discord-notifiers = {
      zfs-scrub.enable = true;
      # zfs-snapshot-frequent.enable = true;
      # zfs-snapshot-hourly.enable = true;
      zfs-snapshot-daily.enable = true;
      zfs-snapshot-weekly.enable = true;
      zfs-snapshot-monthly.enable = true;
      zfs-trim.enable = true;
    };
  };
}
