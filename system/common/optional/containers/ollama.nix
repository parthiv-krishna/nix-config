{
  pkgs,
  ...
}:
let
  serviceName = "ollama";
  subdomain = serviceName;
  dataDir = "/var/lib/${serviceName}";
  port = "11434";
in
{
  virtualisation.oci-containers.containers."${serviceName}" = {
    image = "ollama/ollama:latest";
    autoStart = true;
    ports = [
      "${port}:11434"
    ];
    volumes = [
      "${dataDir}:/root/.ollama"
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

  environment.systemPackages = with pkgs; [
    ollama # for managing
  ];

}
