# ollama configuration

{
  ...
}:

{
  services.ollama.enable = true;

  # persist downloaded models
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/ollama/models"
    ];
  };

}
