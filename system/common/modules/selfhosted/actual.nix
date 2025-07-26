_: {
  custom.selfhosted.actual = {
    enable = true;
    hostName = "nimbus";
    public = true;
    protected = true;
    port = 5006;
    serviceConfig = {
      services.actual = {
        enable = true;
        settings = {
          port = 5006;
        };
      };
    };
    persistentDirs = [
      "/var/lib/private/actual"
    ];
  };
}
