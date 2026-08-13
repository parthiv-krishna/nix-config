# nix-config
My nix flake for system configuration, intended to be usable on NixOS, macOS, and other non-NixOS machines

## Philosophy

I want to write modules once and use/configure them across systems without having to think about whether something is a feature of nixos or of home-manager. This led me to create "features" which are files that can contain nixos, home-manager, or both configurations mixed together. They also can define options that can affect the behavior across both domains. [Features](./modules/features) are enabled and configured on [hosts](./hosts) via the `custom.features.<feature_name>.*` options. [Manifests](./modules/manifests) of several related features can be enabled via `custom.manifests.<manifest_name>.enable`.

This is probably overkill given the relatively small number of machines I have, but oh well.

## Organization

The flake is organized into several directories.

```
hosts/
├── <host_name>/
│   ├── default.nix                 # features, manifests, and other host-specific stuff
│   ├── disks.nix                   # disk configuration using disko
│   └── hardware-configuration.nix  # auto-generated hardware config
│
└── standalone/default.nix          # standalone home-manager config

lib/                                # helpers available at lib.custom.*

modules/
├── features/                       # atomic features available at custom.features.*
│   ├── apps/                       # one app per file (probably hyperbolic)
│   ├── desktop/                    # desktop environment features
│   ├── hardware/                   # anything related to specific hardware on a machine
│   ├── meta/                       # configuring nix/nixos
│   ├── networking/                 # self explanatory
│   ├── selfhosted/                 # selfhosted apps via lib.custom.mkSelfHostedFeature
│   └── storage/                    # self explanatory
│
└── manifests/                      # groups of related features to enable together
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

### macOS
```bash
sudo darwin-rebuild switch --flake .
```

## First-time setup

### NixOS

See [scripts/provisioning/README.md](/scripts/provisioning/README.md).

### Home-manager standalone
First, [install nix](https://nixos.org/download/).

Then install home manager:
```bash
nix-channel --add https://github.com/nix-community/home-manager/archive/master.tar.gz home-manager
nix-channel --update
nix-shell '<home-manager>' -A install
```
Then run the command in the Usage section.

### macOS
First, [install lix](https://lix.systems/install/#on-any-other-linuxmacos-system) (as recommended by the `nix-darwin` docs).

Then, run the following for initial installation (update HOSTNAME to the desired one)
```
sudo nix run nix-darwin/master#darwin-rebuild -- switch --flake .#HOSTNAME
```
