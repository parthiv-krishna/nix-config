# Migration Plan: Unified Modules and Manifests

This document maps every existing file to its new location in the restructured configuration.

## Directory Structure Overview

```
# OLD STRUCTURE (to be removed)
home/
  common/required/
  common/modules/
  {hostname}.nix
system/
  common/required/
  common/modules/
  {hostname}/

# NEW STRUCTURE
hosts/
  standalone/default.nix
  icicle/
  midnight/
  nimbus/
modules/
  features/
    apps/
    desktop/
    hardware/
    meta/
    networking/
    selfhosted/        # Deferred - import as-is
    storage/
  manifests/
lib/
  infra.nix           # NEW: mkFeature, loadFeatures
```

---

## Feature Mapping

### modules/features/apps/

| New File | Source | Type | Notes |
|----------|--------|------|-------|
| `bash.nix` | home/common/required/bash.nix | home-only | mkFeature |
| `git.nix` | home/common/required/git.nix | home-only | mkFeature |
| `tmux.nix` | home/common/required/tmux.nix | home-only | mkFeature |
| `brave.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `discord.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `dolphin.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `element.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `librewolf.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `obsidian.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `thunderbird.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `vscode.nix` | home/common/modules/gui-apps.nix | home-only | Split from gui-apps |
| `audacity.nix` | home/common/modules/sound-engineering.nix | home-only | Split from sound-engineering |
| `musescore.nix` | home/common/modules/sound-engineering.nix | home-only | Split from sound-engineering |
| `reaper.nix` | home/common/modules/sound-engineering.nix | home-only | Split from sound-engineering |
| `kitty.nix` | home/common/modules/hyprland/kitty.nix | home-only | Moved from hyprland subdir |
| `nixvim/` | home/common/required/nixvim/ | home-only | Keep subdirectory structure |
| `opencode/` | home/common/modules/opencode/ | home-only | Keep subdirectory structure |

### modules/features/desktop/

| New File | Source | Type | Notes |
|----------|--------|------|-------|
| `theme.nix` | home/common/modules/theme.nix | home-only | Font and colorscheme config |
| `hyprland/default.nix` | system/common/modules/desktop/*.nix + home/common/modules/hyprland/*.nix | **MERGED** | Unified system+home config |
| `hyprland/hypridle.nix` | home/common/modules/hyprland/hypridle.nix | home-only | Reads from shared idle options |
| `hyprland/waybar.nix` | home/common/modules/hyprland/waybar.nix | home-only | |
| `hyprland/wofi.nix` | home/common/modules/hyprland/wofi.nix | home-only | |
| `hyprland/dunst.nix` | home/common/modules/hyprland/dunst.nix | home-only | |
| `hyprland/hyprpaper.nix` | home/common/modules/hyprland/hyprpaper.nix | home-only | |
| `hyprland/gtk.nix` | home/common/modules/hyprland/gtk.nix | home-only | |

### modules/features/hardware/

| New File | Source | Type | Notes |
|----------|--------|------|-------|
| `audio.nix` | system/common/modules/hardware/audio.nix | system-only | mkFeature |
| `bluetooth.nix` | system/common/modules/hardware/bluetooth.nix | system-only | mkFeature |
| `wifi.nix` | system/common/modules/hardware/wifi.nix | system-only | mkFeature |
| `ups.nix` | system/common/modules/hardware/ups.nix | system-only | mkFeature |
| `seagate-hdd.nix` | system/common/modules/hardware/seagate-hdd.nix | system-only | mkFeature |
| `wake-on-lan.nix` | system/common/modules/hardware/wake-on-lan.nix | system-only | mkFeature |
| `gpu/intel.nix` | system/common/modules/hardware/intel-gpu.nix | system-only | mkFeature |
| `gpu/nvidia.nix` | system/common/modules/hardware/nvidia.nix | system-only | mkFeature |

### modules/features/meta/

| New File | Source | Type | Notes |
|----------|--------|------|-------|
| `auto-upgrade.nix` | system/common/required/auto-upgrade.nix | system-only | mkFeature |
| `impermanence.nix` | system/common/required/impermanence.nix + home/common/modules/impermanence/ | **MERGED** | System + home persistence |
| `parthiv.nix` | system/common/required/parthiv.nix | system-only | User setup, home-manager integration |
| `sops.nix` | system/common/required/sops.nix + home/common/modules/sops.nix | **MERGED** | System + home secrets |
| `unfree.nix` | system/common/modules/unfree.nix + home/common/modules/unfree.nix | **MERGED** | System + home allowlists |
| `discord-notifiers.nix` | system/common/modules/discord-notifiers.nix | system-only | mkFeature |
| `constants.nix` | system/common/modules/constants.nix + home/common/modules/constants.nix | **MERGED** | Read-only constants |
| `restic.nix` | system/common/required/restic.nix | system-only | Backup configuration |

### modules/features/networking/

| New File | Source | Type | Notes |
|----------|--------|------|-------|
| `tailscale.nix` | system/common/required/tailscale.nix | system-only | mkFeature |
| `sshd.nix` | system/common/modules/server/sshd.nix | system-only | mkFeature |
| `wake-on-lan.nix` | system/common/modules/hardware/wake-on-lan.nix | system-only | Move from hardware (it's network-related) |

### modules/features/storage/

| New File | Source | Type | Notes |
|----------|--------|------|-------|
| `samba.nix` | system/common/modules/server/samba.nix | system-only | mkFeature |
| `zfs.nix` | system/common/modules/server/zfs.nix | system-only | mkFeature |

### modules/features/selfhosted/

**DEFERRED** - Keep current structure, import directly in midnight/nimbus hosts.

| Current File | Action |
|--------------|--------|
| `default.nix` | Keep as-is |
| `*.nix` (all services) | Keep as-is |
| `prometheus/*.nix` | Keep as-is |

---

## Manifest Mapping

### modules/manifests/

| New File | Purpose | Features Enabled |
|----------|---------|------------------|
| `required.nix` | Core features for all hosts | apps.git, apps.bash, apps.tmux, meta.tailscale, meta.sops, meta.impermanence, meta.auto-upgrade, meta.parthiv, meta.restic, meta.unfree, meta.constants |
| `desktop-environment.nix` | Full desktop setup | desktop.hyprland, desktop.theme, apps.kitty, apps.brave, apps.element, apps.dolphin, + all gui apps |
| `server.nix` | Server features | networking.sshd |
| `sound-engineering.nix` | Audio production | apps.audacity, apps.musescore, apps.reaper |

---

## Host Mapping

### hosts/icicle/

| New File | Source | Notes |
|----------|--------|-------|
| `default.nix` | system/icicle/default.nix + home/icicle.nix | **MERGED** - unified config |
| `hardware-configuration.nix` | system/icicle/hardware-configuration.nix | Keep as-is |
| `disks.nix` | system/icicle/disks.nix | Keep as-is |

**New default.nix structure:**
```nix
{ lib, inputs, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];

  networking.hostName = "icicle";
  time.timeZone = "America/Los_Angeles";
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  custom = {
    manifests = {
      required.enable = true;
      desktop-environment.enable = true;
      sound-engineering.enable = true;
    };
    
    features = {
      apps.opencode.enable = true;
      
      hardware = {
        audio = {
          enable = true;
          micVolume = 0.5;
        };
        bluetooth.enable = true;
        wifi = {
          enable = true;
          driver = "mt7921e";
        };
      };
      
      desktop.hyprland.idleMinutes = {
        lock = 1;
        screenOff = 2;
        suspend = 3;
      };
      
      meta = {
        impermanence.rootPartitionPath = "/dev/root_vg/root";
        sops.sopsFile = "icicle.yaml";
      };
    };
  };

  system.stateVersion = "24.11";
}
```

### hosts/midnight/

| New File | Source | Notes |
|----------|--------|-------|
| `default.nix` | system/midnight/default.nix + home/midnight.nix | **MERGED** |
| `hardware-configuration.nix` | system/midnight/hardware-configuration.nix | Keep as-is |
| `disks.nix` | system/midnight/disks.nix | Keep as-is |

**New default.nix structure:**
```nix
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    # Import selfhosted directly until refactored
    (lib.custom.relativeToRoot "system/common/modules/selfhosted")
  ];

  networking.hostName = "midnight";
  time.timeZone = "America/Los_Angeles";
  
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
    };
    
    features = {
      apps.opencode.enable = true;
      
      hardware = {
        intel-gpu.enable = true;
        nvidia = {
          enable = true;
          cudaCapability = "8.6";
        };
        seagate-hdd = {
          enable = true;
          disks = [ "/dev/sda" "/dev/sdb" "/dev/sdc" ];
        };
        ups.enable = true;
        wake-on-lan = {
          enable = true;
          device = "enp2s0";
        };
      };
      
      storage = {
        samba.enable = true;
        zfs.enable = true;
      };
      
      meta = {
        impermanence.rootPartitionPath = "/dev/disk/by-partlabel/disk-main-root";
        sops.sopsFile = "midnight.yaml";
      };
    };
  };

  system.stateVersion = "24.11";
}
```

### hosts/nimbus/

| New File | Source | Notes |
|----------|--------|-------|
| `default.nix` | system/nimbus/default.nix + home/nimbus.nix | **MERGED** |
| `hardware-configuration.nix` | system/nimbus/hardware-configuration.nix | Keep as-is |
| `disks.nix` | system/nimbus/disks.nix | Keep as-is |

**New default.nix structure:**
```nix
{ lib, ... }:
{
  imports = [
    ./hardware-configuration.nix
    ./disks.nix
    # Import selfhosted directly until refactored
    (lib.custom.relativeToRoot "system/common/modules/selfhosted")
  ];

  networking.hostName = "nimbus";
  time.timeZone = "America/Los_Angeles";
  
  boot.loader.grub = {
    efiSupport = true;
    efiInstallAsRemovable = true;
    device = "nodev";
  };

  custom = {
    manifests = {
      required.enable = true;
      server.enable = true;
    };
    
    features = {
      apps.opencode.enable = true;
      
      meta = {
        impermanence.rootPartitionPath = "/dev/disk/by-partlabel/disk-main-root";
        sops.sopsFile = "nimbus.yaml";
      };
    };
  };

  system.stateVersion = "24.11";
}
```

### hosts/standalone/

| New File | Source | Notes |
|----------|--------|-------|
| `default.nix` | home/standalone.nix | Standalone home-manager |

**New default.nix structure:**
```nix
{ lib, username, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  home.stateVersion = "24.11";
  
  targets.genericLinux.enable = true;

  custom.features = {
    apps = {
      git.enable = true;
      bash.enable = true;
      tmux.enable = true;
      nixvim.enable = true;
      opencode.enable = true;
    };
  };
}
```

---

## Library Changes

### lib/infra.nix (NEW)

Contains:
- `mkFeature { path, extraOptions?, systemConfig?, homeConfig? }`
- `loadFeatures { path, mode, customLib }`

### lib/default.nix (MODIFIED)

Add:
```nix
infra = import ./infra.nix { inherit lib; };
# ...
custom = {
  inherit scanPaths;
  inherit (infra) mkFeature loadFeatures;
  # ... existing helpers
};
```

### lib/services.nix (KEEP)

Keep `mkSelfHostedService`, `mkPersistentSystemDir`, etc. as-is for selfhosted modules.

---

## Flake Changes

### flake.nix (MODIFIED)

```nix
nixosConfigurations = lib.mapAttrs (
  hostName: hostConfig:
  let
    inherit (hostConfig) system;
    customLib = mkCustomLib system;
  in
  lib.nixosSystem {
    modules = [
      home-manager.nixosModules.home-manager
      (customLib.custom.loadFeatures { 
        path = ./modules/features; 
        mode = "nixos"; 
        inherit customLib;
      })
      ./modules/manifests
      ./hosts/${hostName}
    ];
    specialArgs = {
      inherit inputs;
      lib = customLib;
    };
    inherit system;
  }
) hosts;

homeConfigurations = ... {
  modules = [
    (customLib.custom.loadFeatures { 
      path = ./modules/features; 
      mode = "home"; 
      inherit customLib;
    })
    ./hosts/standalone
  ];
};
```

---

## Migration Order

### Phase 1: Infrastructure
1. [ ] Add `lib/infra.nix` with mkFeature, loadFeatures
2. [ ] Update `lib/default.nix` to export infra functions
3. [ ] Create `modules/features/` and `modules/manifests/` directories
4. [ ] Create `hosts/` directory structure

### Phase 2: Simple Features (system-only or home-only)
5. [ ] Migrate hardware features (bluetooth, audio, wifi, etc.)
6. [ ] Migrate networking features (tailscale, sshd)
7. [ ] Migrate storage features (samba, zfs)
8. [ ] Migrate simple app features (bash, git, tmux)

### Phase 3: Complex Features (merged system+home)
9. [ ] Migrate desktop/hyprland (unified config)
10. [ ] Migrate meta/impermanence (system + home)
11. [ ] Migrate meta/sops (system + home)
12. [ ] Migrate meta/unfree (system + home)

### Phase 4: App Splitting
13. [ ] Split gui-apps.nix into individual app features
14. [ ] Split sound-engineering.nix into individual app features
15. [ ] Migrate nixvim/ subdirectory
16. [ ] Migrate opencode/ subdirectory

### Phase 5: Manifests
17. [ ] Create required.nix manifest
18. [ ] Create desktop-environment.nix manifest
19. [ ] Create server.nix manifest
20. [ ] Create sound-engineering.nix manifest

### Phase 6: Hosts
21. [ ] Migrate hosts/icicle
22. [ ] Migrate hosts/midnight (with selfhosted import)
23. [ ] Migrate hosts/nimbus (with selfhosted import)
24. [ ] Migrate hosts/standalone

### Phase 7: Flake & Cleanup
25. [ ] Update flake.nix
26. [ ] Verify all hosts evaluate
27. [ ] Compare with baseline JSONs
28. [ ] Remove old home/ and system/ directories

---

## Files to Delete After Migration

```
home/
  common/
    required/
    modules/
  icicle.nix
  midnight.nix
  nimbus.nix
  standalone.nix

system/
  common/
    required/
    modules/         # Except selfhosted/ which is imported directly
  icicle/
  midnight/
  nimbus/
```

---

## Verification Checklist

After migration, verify:

- [ ] `nix eval .#nixosConfigurations.icicle.config.system.build.toplevel` succeeds
- [ ] `nix eval .#nixosConfigurations.midnight.config.system.build.toplevel` succeeds
- [ ] `nix eval .#nixosConfigurations.nimbus.config.system.build.toplevel` succeeds
- [ ] `nix eval .#homeConfigurations.parthiv.activationPackage` succeeds
- [ ] Baseline JSON comparison shows expected changes only (custom.* → custom.features.*)
- [ ] Key services still enabled on each host
- [ ] Home programs still enabled on each host
