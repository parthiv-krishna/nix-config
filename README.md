# nix-config
My nix flake for system configuration, intended to be usable on both NixOS and non-NixOS machines

## Flake Organization

The flake is organized into several directories.

```
home/  # home-manager configuration
├── <user>/  # configuration for <user>
│   ├── common/  # home configuration that can be used on multiple systems
│   │   ├── optional/  # home configuration that is enabled on some systems
│   │   └── required/  # home configuration that must be enabled on all systems
│   └── <hostname>.nix  # home configuration for <user>@<hostname>
lib/  # helpers to extend the nixpkgs.lib. all files are
│     # auto-imported and available at lib.custom
modules/  # custom NixOS modules
├── selfhosted/  # self-hosted services that are run on particular hosts using lib.custom.mkSelfHostedService
│   └── <servicename>/
system/  # nixos system configuration
├── <hostname>/  # configuration for <hostname>. each contains a default.nix and hardware-configuration.nix
├── common/  # system configuration that can be used across multiple systems
│   ├── disks/  # declarative disk configurations (using disko)
│   ├── optional/  # system configuration that is enabled on some systems
│   ├── required/  # system configuration that must be enabled on all systems
│   └── users/  # user-specific configuration, each system should import its users
```

## System Architecture

The goal is for users on either my home network or the public internet to be able to access `service.sub0.net` and have it access the service. This is not straightforward, as my network is behind CGNAT, so I don't have the ability to open ports to the public. If a user is on the local network, requests should go directly to the server that host the service. If the user is on the public internet, they're proxied by `nimbus` which has a public IP address.

### Machines
The network consists of three machines.

- `midnight` is my main home server, which contains mass storage and an RTX 3060 for local AI inference. It runs most of my self-hosted services. For energy savings, it is often asleep.
- `vardar` is an always-on Dell Wyse 3040 thin client. It is always on and runs Adguard DNS for my local network, and a [custom Wake on LAN webapp](https://github.com/parthiv-krishna/thaw) to allow users to wake up `midnight` when it's asleep.
- `nimbus` is a cloud-hosted server that primarily acts as a proxy into the network from the public internet. It also runs some frequently accessed services that aren't worth waking up `midnight` for.

The machines are connected together using Tailscale, and all inter-machine traffic is HTTPS tunneled through the Tailscale wireguard connections.

### External Traffic
A user visits `service.sub0.net` on the public internet. Traffic is received by Caddy on `nimbus`.
- CrowdSec bounces suspicious traffic.
- Non-suspicious traffic is `forward_auth` via Authelia as an authentication service at `auth.sub0.net` on `nimbus`.
- The query is `reverse_proxy`'d to the appropriate target machine.
    - If the service is hosted on `nimbus`, this'll just be a localhost:port.
    - Otherwise, it'll reverse proxy via a tailnet URL (e.g. `service.midnight.ts.sub0.net`)
        - On the machine hosting the service, another instance of Caddy will receive the request and `reverse_proxy` it to localhost:port.

### Internal Traffic
- A user visits `service.sub0.net` on my local network. Local DNS entries override the locally-hosted services to point at `midnight` or `vardar` as needed.
- The machine's instance of Caddy will `reverse_proxy` the request to localhost:port without any additional authentication.

## Deployment
Due to the multi-system architecture, I use (colmena)[https://github.com/zhaofengli/colmena] to manage deployment. A single command (`colmena apply`) will push the updates to the configuration to all of the machines.

## Self Hosted Services
The key to the self hosted services setup is `mkSelfHostedService`, defined in [lib/services.nix](./lib/services.nix). `mkSelfHostedService` is a helper that standardizes the configuration and exposure of self-hosted services across the network. It automates the setup of Caddy reverse proxy rules, domain names, authentication, and public/private access, so you only need to specify the service-specific configuration and a few metadata fields. This makes it easy to add new services and ensures consistent, secure access patterns for both internal and external users.

Arguments:
- `name`: The name of the service (used for ports, domains, and group names).
- `hostName`: The machine that actually runs the service.
- `subdomain` (optional): The subdomain to use for the service (defaults to `name`).
- `public` (optional): Whether the service should be exposed to the public internet (default: false).
- `protected` (optional): Whether the service should require authentication via Authelia (default: true).
- `serviceConfig`: The NixOS module fragment that actually enables and configures the service on the target machine.

The function automatically:
- Asserts that Caddy is enabled on the relevant hosts.
- Ensures a port is defined for the service in `config.constants.ports`.
- Sets up Caddy virtual hosts for both internal and public FQDNs.
- Configures Authelia access control for public services.
- Sets up proxying between the public server and the internal host as needed.
