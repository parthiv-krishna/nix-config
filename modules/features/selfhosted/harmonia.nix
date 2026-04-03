# Harmonia - cache server for nix store paths
{ lib }:
let
  port = 5000;
in
lib.custom.mkSelfHostedFeature {
  name = "harmonia";
  subdomain = "cache";
  inherit port;

  homepage = {
    category = "Network";
    description = "Nix binary cache";
    icon = "sh-nix";
    status = "/health";
  };

  serviceConfig =
    _cfg:
    { config, ... }:
    let
      secretsRoot = "harmonia";
    in
    {
      services.harmonia.cache = {
        enable = true;
        signKeyPaths = [ config.sops.secrets."${secretsRoot}/signing-key".path ];
        settings.bind = "127.0.0.1:${toString port}";
      };

      # GH Actions will use this user to push store paths via `nix copy`
      users.users.nix-cache = {
        isSystemUser = true;
        group = "nix-cache";
        shell = "/bin/sh";
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMHmFzigg36zPJIvOXF8NOcVlRa4QSOF2OEBFN1vjPxC github-actions-nix-cache"
        ];
      };
      users.groups.nix-cache = { };

      # allow nix-cache user to push to the nix store and create GC roots
      nix.settings.trusted-users = [ "nix-cache" ];

      # Pre-create GC roots directory owned by nix-cache so CI can create roots without sudo
      systemd.tmpfiles.rules = [
        "d /nix/var/nix/gcroots/cache 0755 nix-cache nix-cache -"
      ];

      sops.secrets."${secretsRoot}/signing-key" = {
        owner = "harmonia";
        group = "harmonia";
        mode = "0400";
      };
    };
}
