# Nix Configuration Restructuring Plan

## Current Structure

Review the nix configuration in this directory. Of particular note is that I have a system/ and a home/ section, each of which contains host-specific configuration, and then common configuration which is further subdivided into required and modules. All hosts import all of the required modules, then some hosts enable some things in the modules/ directory. 

## Goals

Transform this nix configuration into a new format:
1. Remove the structural distinction between `modules` and `required`
2. Remove the structural distinction between `home` and `system`
3. Maintain `lib.custom.scanPaths` functionality (auto-import files)

Currently, there is awkwardness in certain things (e.g. hyprland) being configured in both home and system, and the two configurations don't really talk to each other appropriately.

## Desired Directory Structure

```
hosts/
    standalone/
        default.nix          # home-manager-only setup
    icicle/
        hardware-configuration.nix
        default.nix
        disks.nix
    midnight/
        hardware-configuration.nix
        default.nix
        disks.nix
    nimbus/
        hardware-configuration.nix
        default.nix
        disks.nix

modules/
    features/
        apps/
            default.nix      # lib.custom.scanPaths import everything
            bash.nix
            brave.nix
            discord.nix
            dolphin.nix
            element-desktop.nix
            git.nix
            librewolf.nix
            ... other apps from gui-apps.nix
            audacity.nix
            musescore.nix
            reaper.nix
            nixvim/
                ... nixvim config
            opencode/
            kitty.nix
            ... each distinct app gets its own file
            
        desktop/
            default.nix      # lib.custom.scanPaths + shared desktop config (idle behavior, theme.nix)
            hyprland/
                hypridle.nix # reads from cfg.custom.features.desktop.idle.{dim,lock,sleep}
                default.nix  # merged system + home hyprland config
                ... various hyprland home modules
            gnome/           # future development
            
        hardware/
            default.nix      # lib.custom.scanPaths import everything
            audio.nix
            bluetooth.nix
            gpu/
                default.nix
                intel.nix
                nvidia.nix
            ups.nix
            seagate-hdd.nix
            wifi.nix

        meta/
            default.nix      # lib.custom.scanPaths import everything
            auto-upgrade.nix
            impermanence.nix
            parthiv.nix
            sops.nix
            unfree.nix

        networking/
            default.nix      # lib.custom.scanPaths import everything
            sshd.nix
            tailscale.nix
            wake-on-lan.nix

        selfhosted/
            default.nix      # lib.custom.scanPaths + core selfhosted functionality
            ... all selfhosted stuff (deferred - keep as-is for now)

        storage/
            default.nix      # lib.custom.scanPaths import everything
            samba.nix
            restic.nix
            zfs.nix

    manifests/
        required.nix                # enables all required stuff
        desktop-environment.nix     # enables hyprland and all gui-apps
        server.nix                  # enables server related stuff (sshd)
        sound-engineering.nix       # enables all sound-engineering apps
```

Note: No more distinction between home/system, and modules/required!

Existing lib/, scripts/, and tools/ can be kept as-is.

---

## Implementation Details

### 1. Feature Files (`lib.custom.mkFeature`)

Each feature is created using `mkFeature` which handles all boilerplate:

```nix
# modules/features/hardware/bluetooth.nix
{ lib, ... }:
lib.custom.mkFeature {
  path = ["hardware" "bluetooth"];  # becomes custom.features.hardware.bluetooth
  
  # extraOptions are added alongside the auto-generated `enable` option
  extraOptions = { };
  
  # NixOS system-level config (optional)
  systemConfig = cfg: {
    hardware.bluetooth.enable = true;
    services.blueman.enable = true;
  };
  
  # Home-manager config (optional)
  homeConfig = cfg: {
    # home-manager settings if any
  };
}
```

#### What `mkFeature` Returns

An attrset with two modules:
```nix
{
  nixos = { /* NixOS module */ };
  home = { /* home-manager module */ };
}
```

#### How It Works

**In NixOS mode:**
- Options are defined at `custom.features.{path}.*` in NixOS
- `systemConfig cfg` is applied to NixOS config
- `homeConfig cfg` is injected into `home-manager.sharedModules`
- The `cfg` comes from NixOS options

**In Standalone mode:**
- Options are defined at `custom.features.{path}.*` in home-manager
- `homeConfig cfg` is applied to home-manager config
- The `cfg` comes from home-manager options
- `systemConfig` is ignored (no NixOS)

#### Dual-Mode Config Resolution

Home-manager modules need to work in both modes:
- **NixOS mode**: Read config from `osConfig.custom.features.*`
- **Standalone mode**: Read config from `config.custom.features.*` (shadow options)

Shadow options are always defined in home-manager but ignored when `osConfig` is available.

### 2. Manifest Files

Standard NixOS modules that enable bundles of features:

```nix
# modules/manifests/desktop-environment.nix
{ config, lib, ... }:
{
  options.custom.manifests.desktop-environment.enable = 
    lib.mkEnableOption "desktop environment manifest";
  
  config = lib.mkIf config.custom.manifests.desktop-environment.enable {
    custom.features.desktop.hyprland.enable = lib.mkDefault true;
    custom.features.apps.kitty.enable = lib.mkDefault true;
    custom.features.apps.brave.enable = lib.mkDefault true;
    # ... more features
  };
}
```

- Use `mkDefault` so hosts can override with `= false`
- Can set sensible defaults for non-enable options
- Can include assertions (e.g., required manifest asserts it's enabled)

### 3. Host Files (`lib.custom.mkHost`)

`mkHost` handles boilerplate for host configuration:

```nix
# hosts/icicle/default.nix
{ lib, inputs, ... }:
lib.custom.mkHost {
  hostName = "icicle";
  stateVersion = "24.11";  # populates both system.stateVersion and home.stateVersion
  
  # Optional: extra imports like nixos-hardware modules
  extraImports = [
    inputs.nixos-hardware.nixosModules.framework-13-7040-amd
  ];
  
  # The custom configuration block
  config = {
    manifests = {
      required.enable = true;
      desktop-environment.enable = true;
      sound-engineering.enable = true;
    };

    features = {
      desktop.idle = {
        dim = 15;
        lock = 20;
        sleep = 30;
      };
      
      apps.opencode.enable = true;

      hardware.wifi = {
        enable = true;
        driver = "mt7921e";
      };
    };
  };
}
```

`mkHost` automatically:
- Imports `./hardware-configuration.nix` and `./disks.nix`
- Sets `networking.hostName`
- Sets `system.stateVersion` and `home.stateVersion`
- Applies the `custom = { ... }` config block

### 4. Module Loading (`lib.custom.loadFeatures`)

New helper to load features with the right mode:

```nix
loadFeatures = { path, mode }:
  let
    files = scanPaths path;
    features = map import files;
    modules = map (f: f.${mode}) features;  # mode = "nixos" or "home"
  in
  { imports = modules; };
```

### 5. Flake Integration

```nix
# flake.nix
nixosConfigurations.icicle = lib.nixosSystem {
  modules = [
    (lib.custom.loadFeatures { path = ./modules/features; mode = "nixos"; })
    ./modules/manifests  # standard scanPaths
    ./hosts/icicle
  ];
};

homeConfigurations.parthiv = home-manager.lib.homeManagerConfiguration {
  modules = [
    (lib.custom.loadFeatures { path = ./modules/features; mode = "home"; })
    ./hosts/standalone
  ];
};
```

---

## Library Structure

New file `lib/infra.nix` containing:
- `mkFeature` - create feature modules
- `mkHost` - create host configurations  
- `loadFeatures` - load features with mode selection

Existing `lib/default.nix` keeps:
- `scanPaths` - directory scanning
- `relativeToRoot` - path helpers

---

## Notes

- **Selfhosted**: Currently spaghetti code that breaks the abstraction. For now, midnight/nimbus will import selfhosted directly and let it handle splitting. Fix later.
- **Single user assumption**: This design assumes all machines have one user (parthiv), making the unified config transparent.
- **Apps category**: Everything user-facing is an "app" (bash, git, brave, etc.). Meta is for nixos/configuration infrastructure.

---

## Implementation Plan

### Step 1: Establish Baseline ✓
- Verify current configs evaluate
- Save baseline JSON extracts for comparison
- Fixed issues found:
  - grafana secret_key missing
  - Options without defaults (cudaCapability, device, driver, sopsFile, micVolume)

### Step 2: Create Prototype
Build two minimal test configurations:

**2a. Current structure mock** (`prototype/current/`):
- 2 hosts (testhost, standalone)
- 2 required modules per home/system
- 2 optional modules per home/system
- One module spans both home and system (simplified hyprland)

**2b. New structure mock** (`prototype/new/`):
- Same features but using mkFeature/mkHost/loadFeatures
- Validate the approach works
- Ensure evaluation matches current structure

### Step 3: Full Migration Plan
Create complete tree of new feature, manifest, and host files with comments indicating:
- Source file(s) for each new file
- Any merging (e.g., hyprland home+system → single file)
- Any splitting (e.g., gui-apps.nix → multiple app files)

### Step 4: Execute Migration
- Migrate files according to plan
- Verify evaluation matches baseline at the end
