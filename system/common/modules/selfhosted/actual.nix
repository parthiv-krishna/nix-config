{
  config,
  ...
}:
{
  custom.selfhosted.actual = {
    enable = true;
    hostName = "nimbus";
    public = true;
    protected = true;
    port = 5006;
    config = {
      services.actual = {
        enable = true;
        settings = {
          inherit (config.custom.selfhosted.actual) port;
        };
      };
    };
    persistentDirs = [
      "/var/lib/private/actual"
    ];
  };
}
