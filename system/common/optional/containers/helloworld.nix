_:
let
  port = "43110";
  serviceName = "helloworld";
in
{
  virtualisation.oci-containers.containers."${serviceName}" = {
    image = "docker.io/nginxdemos/hello";
    autoStart = true;
    ports = [
      # hello
      "${port}:80"
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers."${serviceName}" = {
      rule = "Host(`${serviceName}.sub0.net`)";
      service = serviceName;
      entryPoints = [ "websecure" ];
    };
    services."${serviceName}".loadBalancer.servers = [ { url = "http://localhost:${port}"; } ];
  };
}
