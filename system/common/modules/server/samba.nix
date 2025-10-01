{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.samba;
  rootPath = "/var/lib/samba";
  publicPath = "${rootPath}/public";
in
{
  options.custom.samba = {
    enable = lib.mkEnableOption "custom.samba";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.samba = {
          enable = true;
          settings = {
            global = {
              "workgroup" = "WORKGROUP";
              "server string" = config.networking.hostName;
              "netbios name" = config.networking.hostName;
              "security" = "user";
              # allow access over tailscale
              "hosts allow" = "100.64.0.0/10 127.0.0.1 localhost";
              "hosts deny" = "0.0.0.0/0";
              "interfaces" = "lo";
              "bind interfaces only" = "yes";
              "smb ports" = "445";
              "map to guest" = "never";
            };

            "public" = {
              "path" = publicPath;
              "comment" = "Public Files";
              "valid users" = "@samba-users";
              "writeable" = "yes";
              "create mask" = "0664";
              "directory mask" = "0775";
              "force group" = "samba-users";
            };
          };
        };
      }
      (lib.custom.mkPersistentSystemDir {
        directory = rootPath;
        user = "samba";
        mode = "0755";
      })
    ]
  );
}
