{
  config,
  lib,
  pkgs,
  ...
}:
let
  # need to keep in sync with tailscale fallback DNS
  host = config.constants.hosts.nimbus;
  port = 3030;
in
lib.custom.mkSelfHostedService {
  inherit config lib;
  name = "adguard";
  inherit port;
  hostName = host.name;
  subdomain = "dns";
  public = false;
  protected = true;
  homepage = {
    category = config.constants.homepage.categories.admin;
    description = "Internal Domain Name Resolution";
    icon = "sh-adguard-home";
  };
  persistentDirectories = [ "/var/lib/private/AdGuardHome" ];
  serviceConfig = {
    services = {
      adguardhome = {
        enable = true;
        host = "0.0.0.0";
        inherit port;
        settings = {
          dns = {
            bind_hosts = host.ips;
            port = 53;
            upstream_dns = [
              # quad9
              "9.9.9.9"
              "149.112.112.112"
            ];
          };
        };
      };
    };

    environment.systemPackages = with pkgs; [
      adguardian
    ];
  };
}
