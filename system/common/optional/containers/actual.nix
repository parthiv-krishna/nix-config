_:
let
  serviceName = "actual";
  subdomain = serviceName;
  dataDir = "/var/lib/${serviceName}";
  port = "5006";
in
{
  virtualisation.oci-containers.containers.${serviceName} = {
    image = "actualbudget/actual-server:latest";
    autoStart = true;
    ports = [
      "${port}:5006"
    ];
    volumes = [
      dataDir
    ];
  };

  environment.persistence."/persist/system" = {
    directories = [
      dataDir
    ];
  };

  services.traefik.dynamicConfigOptions.http = {
    routers."${serviceName}" = {
      rule = "Host(`${subdomain}.sub0.net`)";
      service = serviceName;
      entryPoints = [ "websecure" ];
    };
    services."${serviceName}".loadBalancer.servers = [ { url = "http://localhost:${port}"; } ];
  };

}
