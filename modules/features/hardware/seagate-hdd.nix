# Seagate disk management feature - system-only
{ lib }:
lib.custom.mkFeature {
  path = [ "hardware" "seagate-hdd" ];

  extraOptions = {
    disks = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "List of Seagate disk devices";
      example = [
        "/dev/sda"
        "/dev/sdb"
      ];
    };

    timers = {
      idleA = lib.mkOption {
        type = lib.types.int;
        default = 100;
        description = "Idle A timer in milliseconds (full rpm)";
      };

      idleB = lib.mkOption {
        type = lib.types.int;
        default = 120000;
        description = "Idle B timer in milliseconds (park heads)";
      };

      idleC = lib.mkOption {
        type = lib.types.int;
        default = 600000;
        description = "Idle C timer in milliseconds (reduce rpm)";
      };

      standbyZ = lib.mkOption {
        type = lib.types.int;
        default = 900000;
        description = "Standby Z timer in milliseconds (spin down)";
      };
    };
  };

  systemConfig = cfg: { pkgs, ... }: {
    environment.systemPackages = with pkgs; [
      openseachest
    ];

    systemd.services."seagate-spindown" = {
      description = "Configure Seagate Exos EPC spindown timers";
      wantedBy = [ "multi-user.target" ];
      script = ''
        ${builtins.concatStringsSep "\n" (
          map (dev: ''
              ${pkgs.openseachest}/bin/openSeaChest_PowerControl -d `realpath ${dev}` \
                --idle_a ${toString cfg.timers.idleA} \
                --idle_b ${toString cfg.timers.idleB} \
                --idle_c ${toString cfg.timers.idleC} \
                --standby_z ${toString cfg.timers.standbyZ}

            echo "Set ${dev} to \
            idle_a=${toString cfg.timers.idleA}ms, \
            idle_b=${toString cfg.timers.idleB}ms, \
            idle_c=${toString cfg.timers.idleC}ms, \
            standby_z=${toString cfg.timers.standbyZ}ms"
          '') cfg.disks
        )}
      '';
      serviceConfig = {
        Type = "oneshot";
        User = "root";
      };
    };
  };
}
