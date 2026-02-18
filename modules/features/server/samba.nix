{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.samba;
  rootPath = "/var/lib/samba";
  publicPath = "${rootPath}/data/public";
  port = toString 445;
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
          nmbd.enable = false;
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
              "smb ports" = "${port}";
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

        users = {
          groups.samba-users = { };
          users.parthiv.extraGroups = [ "samba-users" ];
        };

        systemd.services.tailscale-serve-samba = {
          description = "Serve samba share over tailscale";
          after = [
            "tailscaled.service"
            "smbd.service"
          ];
          wants = [
            "tailscaled.service"
            "smbd.service"
          ];
          wantedBy = [ "multi-user.target" ];

          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = "${pkgs.tailscale}/bin/tailscale serve --bg --tcp ${port} tcp://localhost:${port}";
            ExecStop = "${pkgs.tailscale}/bin/tailscale serve --bg --tcp ${port} off";
            User = "root";
          };
        };
      }
      (lib.custom.mkPersistentSystemDir {
        directory = rootPath;
        user = "root";
        group = "samba-users";
        mode = "0755";
      })
    ]
  );
}
