# ollama configuration

{
  ...
}:

{
  services.ollama = {
    enable = true;
    user = users.users.ollama;
  };

  # persist downloaded models
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/ollama/models"
    ];
  };

  users.users.ollama = {
    # Marks this as a non-login system account
    isSystemUser = true;
    group = "ollama";
    home = "/var/lib/ollama";
  };
  users.groups.ollama = { };

}
