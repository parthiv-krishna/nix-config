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
    }:
    {
      inherit name system tags;
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
    };
    midnight = mkHost {
      name = "midnight";
      system = systems.x86;
      tags = [ tags.server ];
    };
    nimbus = mkHost {
      name = "nimbus";
      system = systems.arm;
      tags = [ tags.server ];
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
