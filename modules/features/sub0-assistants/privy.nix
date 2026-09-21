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
      sops.secrets = {
        "sub0-assistants/zulip_api_keys/privy" = { };
        "sub0-assistants/abilities/actual/server_password" = {
          restartUnits = [ "sub0-assistants-privy-actual.service" ];
        };
        "sub0-assistants/abilities/actual/budget_encryption_password" = {
          restartUnits = [ "sub0-assistants-privy-actual.service" ];
        };
      };

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
        abilities.actual = {
          enable = true;
          url = "https://actual.sub0.net";
          syncId = constants.abilities.actual.budget_sync_id;
          passwordFile = config.sops.secrets."sub0-assistants/abilities/actual/server_password".path;
          encryptionPasswordFile =
            config.sops.secrets."sub0-assistants/abilities/actual/budget_encryption_password".path;
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
          user = "sub0-assistants-privy";
          group = "sub0-assistants-privy";
          mode = "0700";
        }
        {
          directory = "/var/lib/sub0-assistants/abilities/actual/privy";
          user = "sub0-assistants-privy-actual";
          group = "sub0-assistants-privy-actual";
          mode = "0700";
        }
      ];
    };
}
