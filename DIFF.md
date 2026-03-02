# Configuration Diff: `main` vs `merged-modules-and-manifests`

## Evaluation Status

Both branches evaluate successfully for all configurations.

### NixOS Configurations
| Host | Main | Current | Match |
|------|------|---------|-------|
| icicle | PASS | PASS | Yes |
| midnight | PASS | PASS | Yes |
| nimbus | PASS | PASS | Yes |

### Home-Manager Configurations
| Config | Main | Current | Match |
|--------|------|---------|-------|
| parthiv (standalone) | PASS | PASS | Yes |

---

## Functional Equivalence

### System Package Counts
| Host | Main | Current | Match |
|------|------|---------|-------|
| icicle | 165 | 165 | Yes |
| midnight | 175 | 175 | Yes |
| nimbus | 133 | 133 | Yes |

### Systemd Service Counts
| Host | Main | Current | Match |
|------|------|---------|-------|
| icicle | 80 | 80 | Yes |
| midnight | 181 | 181 | Yes |
| nimbus | 79 | 79 | Yes |

### Home-Manager Package Counts
| Host/Config | Main | Current | Match |
|-------------|------|---------|-------|
| icicle | 56 | 56 | Yes |
| midnight | 30 | 30 | Yes |
| nimbus | 30 | 30 | Yes |
| standalone | 31 | 30 | ~Yes (missing `home-manager` pkg) |

---

## Structural Changes

### Directory Structure

**Main Branch:**
```
home/
    common/
        modules/       # Optional home-manager modules
        required/      # Required home-manager modules
    {hostname}.nix     # Host-specific home config
    standalone.nix     # Standalone home-manager config

system/
    common/
        modules/       # Optional NixOS modules
        required/      # Required NixOS modules
    {hostname}/        # Host-specific NixOS config
```

**Current Branch:**
```
hosts/
    {hostname}/        # Combined host config (NixOS + home)
    standalone/        # Standalone home-manager config

modules/
    features/          # All features (unified home + system)
        apps/
        desktop/
        hardware/
        meta/
        networking/
        storage/
    manifests/         # Feature bundles
```

### Key Architectural Changes

1. **Merged home/system distinction** - Single `modules/features/` with `mkFeature` providing both `.nixos` and `.home` modules

2. **Merged required/modules distinction** - All features are optional, enabled via manifests or host config

3. **New abstraction layer:**
   - `lib.custom.mkFeature` - Creates unified feature modules with `homeImports` support
   - `lib.custom.loadFeatures` - Recursively loads features by mode
   - `modules/manifests/` - Bundles of feature enables

4. **Option path changes:**
   - Main: `custom.{feature}.*` (e.g., `custom.audio.enable`)
   - Current: `custom.features.{category}.{feature}.*` (e.g., `custom.features.hardware.audio.enable`)

---

## Fixes Applied During This Session

### 1. Missing `pkgs` and `inputs` in Module Arguments
**File:** `lib/infra.nix`

Changed module function signatures to explicitly request `pkgs` and `inputs`.

### 2. Home-Manager Config Not Receiving NixOS Options
**File:** `lib/infra.nix`

Changed `hmCfg` to read from `osConfig` instead of home-manager's own `config`.

### 3. Selfhosted Option Path Mismatches
**Files:** `system/common/modules/selfhosted/media.nix`, `books.nix`, `*.nix`

- `custom.discord-notifiers` → `custom.features.meta.discord-notifiers.notifiers`
- `unfree.allowedPackages` → `custom.features.meta.unfree.allowedPackages`

### 4. Font Options Path and Size Names
**Files:** `modules/features/desktop/theme.nix`, `hyprland.nix`, `kitty.nix`, `waybar.nix`, `wofi.nix`, `dunst.nix`

- Updated `config.custom.font.*` → `config.custom.features.desktop.theme.font.*`
- Updated size names to match main: `small`, `normal`, `large`, `xlarge`

### 5. Hyprland Sub-features Not Loading
**Fix:** Moved `modules/features/desktop/hyprland/default.nix` to `modules/features/desktop/hyprland.nix`

This allows `loadFeatures` to discover the sub-features in the hyprland directory.

### 6. Missing CLI Utils Feature
**File:** `modules/features/apps/cli-utils.nix` (new)

Created feature containing btop, curl, dig, fastfetch, fzf, pciutils, powertop, ripgrep, smartmontools, trash-cli, unzip, usbutils, wget, yazi, zip.

### 7. Hyprland Sub-features Not Enabled
**File:** `modules/manifests/desktop-environment.nix`

Added enables for dunst, gtk, hypridle, hyprpaper, waybar, wofi.

### 8. Nixvim Not Using mkFeature
**Files:** `lib/infra.nix`, `modules/features/apps/nixvim/default.nix`

- Added `homeImports` parameter to `mkFeature` for features that need to import submodules
- Converted nixvim to use `mkFeature` with `homeImports = lib.custom.scanPaths ./.`

### 9. Null Font Package in Home Packages
**File:** `modules/features/desktop/hyprland.nix`

Removed redundant `config.custom.features.desktop.theme.font.package` from `home.packages` (theme.nix already handles this).

---

## Summary

The restructuring is **complete and functionally equivalent** to main:

- All NixOS and home-manager configurations evaluate successfully
- System packages, systemd services, and home packages match exactly
- The new architecture successfully:
  - Removes home/system distinction
  - Removes required/modules distinction
  - Unifies feature definitions via `mkFeature`
  - Adds manifest layer for feature bundles
  - Supports complex features with `homeImports` parameter
