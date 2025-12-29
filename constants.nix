# pure nix definition of constants
# constants.nix files in system/ and home/ bring these
# into the nixos/home-manager module system
let
  # grab mkInternalFqdn helper
  inherit (import ./lib/domains.nix { }) mkInternalFqdn;

  domains = {
    public = "sub0.net";
    internal = "ts.sub0.net";
  };

  mkHost =
    {
      name,
      system,
      tags,
      ip,
    }:
    {
      inherit name system tags;
      ip = {
        inherit (ip) v4 v6;
      };
      ips = [
        ip.v4
        ip.v6
      ];
      # just need the domains, this avoids circular dependency
      fqdn = mkInternalFqdn { inherit domains; } "" name;
    };

  systems = {
    x86 = "x86_64-linux";
    arm = "aarch64-linux";
  };

  tags = {
    client = "client";
    server = "server";
  };
in
{
  inherit systems tags domains;

  hosts = {
    icicle = mkHost {
      name = "icicle";
      system = systems.x86;
      tags = [ tags.client ];
      ip = {
        v4 = "100.74.68.49";
        v6 = "fd7a:115c:a1e0::501:4437";
      };
    };
    midnight = mkHost {
      name = "midnight";
      system = systems.x86;
      tags = [ tags.server ];
      ip = {
        v4 = "100.82.111.22";
        v6 = "fd7a:115c:a1e0::5d01:8784";
      };
    };
    nimbus = mkHost {
      name = "nimbus";
      system = systems.arm;
      tags = [ tags.server ];
      ip = {
        v4 = "100.122.154.1";
        v6 = "fd7a:115c:a1e0::cf01:9a02";
      };
    };
  };

  publicServerHost = "nimbus";

  homepage = {
    categories = {
      media = "Media";
      storage = "Storage";
      tools = "Tools";
      admin = "Admin";
    };
  };
}
