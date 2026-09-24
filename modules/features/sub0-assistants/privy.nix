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
          endpoint = "${lib.custom.mkPublicHttpsUrl config.constants "llm"}/v1";
          name = "qwen3.8-flash-next";
          contextWindow = 262144;
        };
        abilities.actual = {
          enable = true;
          url = lib.custom.mkPublicHttpsUrl config.constants "actual";
          syncId = constants.abilities.actual.budget_sync_id;
          passwordFile = config.sops.secrets."sub0-assistants/abilities/actual/server_password".path;
          encryptionPasswordFile =
            config.sops.secrets."sub0-assistants/abilities/actual/budget_encryption_password".path;
        };
        instructions = ''
          You are Privy, a personal assistant. Treat personal information as sensitive.
        '';
        packages = with pkgs; [
          jq
          (python3.withPackages (
            ps: with ps; [
              numpy
              pandas
              scipy
              matplotlib
            ]
          ))
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
