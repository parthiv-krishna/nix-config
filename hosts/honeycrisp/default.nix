# Configuration for honeycrisp (Apple Silicon Mac)
{
  networking.hostName = "honeycrisp";
  time.timeZone = "America/Los_Angeles";

  custom = {
    manifests = {
      darwin.enable = true;
      laptop.enable = true;
      required.enable = true;
      sound-engineering.enable = true;
    };

    features = {
      apps = {
        # not available on darwin
        pi.enable = true;
        powertop.enable = false;
      };

      # macOS manages these
      hardware = {
        audio.enable = false;
        bluetooth.enable = false;
      };

      # TODO fix auto upgrade?
      meta = {
        auto-upgrade.enable = false;
        impermanence.enable = false;
        sops.enable = false;
      };

      storage.restic.enable = false;
      systemd.zulip-notifiers.enable = false;
    };
  };

  system.stateVersion = 6;
}
