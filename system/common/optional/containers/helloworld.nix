_: {
  virtualisation.oci-containers.containers.helloworld = {
    image = "docker.io/nginxdemos/hello";
    autoStart = true;
    ports = [
      "81:80"
    ];
  };

  networking.firewall.allowedTCPPorts = [ 81 ];

}
