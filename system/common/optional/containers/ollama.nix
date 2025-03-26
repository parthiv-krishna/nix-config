{
  lib,
  ...
}:
let
  dataDir = "/containers/ollama";
in
{
  virtualisation.docker.enable = lib.mkForce true;
  users.users.parthiv.extraGroups = [ "docker" ];

  virtualisation.oci-containers.containers.ollama = {
    image = "ollama/ollama:latest";
    autoStart = true;
    ports = [
      "11434:11434"
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

}
