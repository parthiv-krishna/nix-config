{
  lib,
  ...
}:
let
  dataDir = "/containers/actual";
in
{
  virtualisation.docker.enable = lib.mkForce true;
  users.users.parthiv.extraGroups = [ "docker" ];

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
