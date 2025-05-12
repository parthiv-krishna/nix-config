{
  helpers,
  pkgs,
  ...
}:
{
  imports = [
    (helpers.mkServiceUser {
      serviceName = "adguardhome";
      userName = "adguardhome";
      dirName = "AdGuardHome";
    })
  ];

  services.adguardhome = {
    enable = true;
    settings = {
      http = {
        address = "0.0.0.0:3000"; # Listen on all interfaces
      };
      dns = {
        bind_host = "0.0.0.0"; # Listen on all interfaces
        port = 53; # Standard DNS port
        upstream_dns = [
          "9.9.9.9" # Quad9
          "149.112.112.112" # also Quad9
        ];
      };
    };
  };

  networking.firewall = {
    enable = true;
    allowedTCPPorts = [
      53 # DNS
      3000 # web UI
    ];
    allowedUDPPorts = [ 53 ]; # DNS
  };

  environment.systemPackages = with pkgs; [
    adguardian
  ];

}
