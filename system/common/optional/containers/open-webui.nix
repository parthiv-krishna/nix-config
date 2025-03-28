_:
let
  serviceName = "open-webui";
  subdomain = "ai";
  dataDir = "/var/lib/${serviceName}";
  port = "3000";
in
{
  virtualisation.oci-containers.containers.${serviceName} = {
    image = "ghcr.io/open-webui/open-webui:cuda";
    autoStart = true;
    ports = [
      "${port}:8080"
    ];
    volumes = [
      dataDir
    ];
    # enable NVIDIA GPU
    extraOptions = [ "--device=nvidia.com/gpu=all" ];
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
