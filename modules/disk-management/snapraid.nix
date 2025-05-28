{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.custom.snapraid;

  # function to generate content file paths
  mkContentFiles =
    dataDisks: map (disk: "${disk}/snapraid-${builtins.baseNameOf disk}.content") dataDisks;

  # function to generate parity file paths
  mkParityFiles =
    parityDisks: map (disk: "${disk}/snapraid-${builtins.baseNameOf disk}.parity") parityDisks;

  # function to convert data disk list to attrset format expected by nixpkgs
  mkDataDisks =
    dataDisks:
    builtins.listToAttrs (
      lib.lists.imap0 (i: disk: {
        name = "d${toString i}";
        value = disk;
      }) dataDisks
    );
in
{
  options.custom.snapraid = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable SnapRAID";
    };

    dataDisks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of data disk paths for SnapRAID";
      example = [
        "/array/disk/data0"
        "/array/disk/data1"
      ];
    };

    parityDisks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of parity disk paths for SnapRAID";
      example = [
        "/array/disk/parity0"
        "/array/disk/parity1"
      ];
    };

    exclude = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "/tmp/"
        "/lost+found/"
      ];
      description = "Paths to exclude from SnapRAID protection";
    };

    scrubInterval = lib.mkOption {
      type = lib.types.str;
      default = "Mon *-*-* 02:00:00";
      description = "Interval for SnapRAID scrub operations";
      example = "weekly";
    };

    scrubPlan = lib.mkOption {
      type = lib.types.int;
      default = 8;
      description = "Percent of the array that should be checked by snapraid scrub";
    };

    scrubOlderThan = lib.mkOption {
      type = lib.types.int;
      default = 10;
      description = "Number of days since data was last scrubbed before it can be scrubbed again";
    };
  };

  config = lib.mkIf cfg.enable {
    # use the built-in nixpkgs snapraid service
    services.snapraid = {
      enable = true;
      dataDisks = mkDataDisks cfg.dataDisks;
      parityFiles = mkParityFiles cfg.parityDisks;
      contentFiles = mkContentFiles cfg.dataDisks;
      inherit (cfg) exclude;
      scrub = {
        interval = cfg.scrubInterval;
        plan = cfg.scrubPlan;
        olderThan = cfg.scrubOlderThan;
      };

    };
    environment.systemPackages = with pkgs; [
      snapraid
    ];
  };
}
