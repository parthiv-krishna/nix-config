# nix-config
My nix flake for system configuration, intended to be usable on both NixOS and non-NixOS machines

## Flake Organization

The flake is organized into several directories.

```
home/  # home-manager configuration
├── common/  # home configuration that can be used on multiple systems
│   ├── modules/  # home configuration that can be enabled on some systems
│   └── required/  # home configuration that must be enabled on all systems
└── <hostname>.nix  # home configuration for <user>@<hostname>
lib/  # helpers to extend the nixpkgs.lib. all files are
│     # auto-imported and available at lib.custom
system/  # nixos system configuration
├── <hostname>/  # configuration for <hostname>. each contains a default.nix and hardware-configuration.nix
└── common/  # system configuration that can be used across multiple systems
    ├── disks/  # declarative disk configurations (using disko)
    ├── modules/  # custom modules that can be enabled on some systems
    └── required/  # system configuration that must be enabled on all systems
```

## Usage

### NixOS
```bash
sudo nixos-rebuild switch --flake .
```

### Home-manager standalone
```bash
home-manager switch --flake .
```

## First-time setup

### NixOS

TODO

### Home-manager standalone
First, [install nix](https://nixos.org/download/)
```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```
Then run the command in the Usage section.
