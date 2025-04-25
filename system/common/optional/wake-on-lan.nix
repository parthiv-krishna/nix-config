{
  device ? throw "set this to the nic for wake on LAN",
  pkgs,
  ...
}:

{
  # enable wake on LAN
  networking.interfaces."${device}".wakeOnLan = {
    enable = true;
    policy = [ "magic" ];
  };

  environment.systemPackages = with pkgs; [
    ethtool
  ];

  systemd.services.enable-wol = {
    description = "Enable Wake-on-LAN";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.ethtool}/bin/ethtool -s ${device} wol g";
    };
  };

}
