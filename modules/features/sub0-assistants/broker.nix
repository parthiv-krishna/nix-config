{ lib }:
lib.custom.mkFeature {
  path = [ "sub0-assistants" ];
  systemConfig = _cfg: _: {
    services.sub0-assistants = {
      enable = true;
      zulip.url = "https://chat.sub0.net";
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
