_:
let
  serviceName = "forgejo";
  subdomain = "git";
  dataDir = "/var/lib/${serviceName}";
  port = "3001";
in
{
  virtualisation.oci-containers.containers.${serviceName} = {
    image = "codeberg.org/forgejo/forgejo:10";
    autoStart = true;
    ports = [
      "${port}:3000"
    ];
    volumes = [
      "${dataDir}:/forgejo"
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
