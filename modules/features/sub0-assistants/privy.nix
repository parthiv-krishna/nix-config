{ lib }:
lib.custom.mkFeature {
  path = [
    "sub0-assistants"
    "privy"
  ];
  systemConfig =
    _cfg:
    { config, pkgs, ... }:
    let
      constants = config.constants.secrets.sub0-assistants;
    in
    lib.mkIf config.custom.features.sub0-assistants.enable {
      sops.secrets."sub0-assistants/zulip_api_keys/privy" = { };

      services.sub0-assistants.agents.privy = {
        zulip = {
          inherit (constants.agents.privy) userId email;
          apiKeyFile = config.sops.secrets."sub0-assistants/zulip_api_keys/privy".path;
          channels = [ constants.channels.bots_private ];
        };
        model = {
          endpoint = "https://llm.sub0.net/v1";
          name = "qwen3-next";
          contextWindow = 65536;
        };
        instructions = ''
          You are Privy, a personal assistant. Treat personal information as sensitive.
          Use your home directory for persistent notes and work.
          Communicate through Zulip. Finish each turn with a helpful response using
          zulip send --message-file <file> --end, including when asking a question.
        '';
        packages = with pkgs; [
          jq
          ripgrep
        ];
      };

      environment.persistence."/persist/system".directories = [
        {
          directory = "/var/lib/sub0-assistants/home/privy";
          user = "sub0-assistant-privy";
          group = "sub0-assistant-privy";
          mode = "0700";
        }
      ];
    };
}
