{ lib }:
lib.custom.mkFeature {
  path = [ "sub0-assistants" ];
  systemConfig = _cfg: { config, ... }: {
    services.sub0-assistants = {
      enable = true;
      zulip.url = lib.custom.mkPublicHttpsUrl config.constants "chat";
    };
    environment.persistence."/persist/system".directories = [
      {
        directory = "/var/lib/sub0-assistants/broker";
        user = "sub0-assistants";
        group = "sub0-assistants";
        mode = "0700";
      }
    ];
  };
}
