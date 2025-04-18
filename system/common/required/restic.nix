{
  config,
  pkgs,
  ...
}:
let
  secretRoot = "${config.networking.hostName}/restic";
  secretPassword = "${secretRoot}/password";
  secretRepository = "${secretRoot}/repository";
  secretEnvironment = "${secretRoot}/environment";
in
{
  environment.systemPackages = with pkgs; [
    restic
  ];

  services.restic.backups.digitalocean = {
    paths = [
      "/persist/home/parthiv"
      "/data"
    ];
    exclude = [ "/data/nobackup" ];
    passwordFile = config.sops.secrets."${secretPassword}".path;
    repositoryFile = config.sops.secrets."${secretRepository}".path;
    environmentFile = config.sops.secrets."${secretEnvironment}".path;
    timerConfig = {
      OnCalendar = "07:00"; # 12am PT
      Persistent = true;
    };
    initialize = true;
    pruneOpts = [
      "--keep-daily 7"
      "--keep-weekly 3"
      "--keep-monthly 3"
    ];
  };

  sops.secrets = {
    "${secretPassword}" = { };
    "${secretRepository}" = { };
    "${secretEnvironment}" = { };
  };
}
