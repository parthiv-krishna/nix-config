_:
let
  dataDir = "/var/lib/actual";
in
{
  virtualisation.oci-containers.containers.actual = {
    image = "actualbudget/actual-server:latest";
    autoStart = true;
    ports = [
      "5006:5006"
    ];
    volumes = [
      dataDir
    ];
  };

  networking.firewall.allowedTCPPorts = [ 5006 ];

  environment.persistence."/persist/system" = {
    directories = [
      dataDir
    ];
  };

}
