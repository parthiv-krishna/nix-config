{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.sshd;
in
{
  options.custom.sshd = {
    enable = lib.mkEnableOption "custom.sshd";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        services.openssh = {
          enable = true;
          # require public-key auth
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
          };
          openFirewall = true;
        };

        # persist SSH host keys
        environment.persistence."/persist/system" = {
          files = [
            "/etc/ssh/ssh_host_ed25519_key"
            "/etc/ssh/ssh_host_ed25519_key.pub"
            "/etc/ssh/ssh_host_rsa_key"
            "/etc/ssh/ssh_host_rsa_key.pub"
          ];
        };
      }
    ]
  );
}
