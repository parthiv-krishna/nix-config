{ lib }:
lib.custom.mkFeature {
  path = [
    "sub0-assistants"
    "aurora"
  ];
  systemConfig =
    _cfg:
    { config, pkgs, ... }:
    let
      constants = config.constants.secrets.sub0-assistants;
    in
    lib.mkIf config.custom.features.sub0-assistants.enable {
      sops.secrets = {
        "sub0-assistants/zulip_api_keys/aurora" = { };
        "sub0-assistants/model_api_keys/nvidia" = { };
      };

      services.sub0-assistants.agents.aurora = {
        zulip = {
          inherit (constants.agents.aurora) userId email;
          apiKeyFile = config.sops.secrets."sub0-assistants/zulip_api_keys/aurora".path;
          channels = [ constants.channels.bots_public ];
        };
        model = {
          endpoint = "https://integrate.api.nvidia.com/v1";
          name = "nvidia/nemotron-3-super-120b-a12b";
          apiKeyFile = config.sops.secrets."sub0-assistants/model_api_keys/nvidia".path;
        };
        abilities.searxng = {
          enable = true;
          url = lib.custom.mkPublicHttpsUrl config.constants "search";
        };
        instructions = ''
          You are Aurora, a general-purpose assistant.
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
          directory = "/var/lib/sub0-assistants/home/aurora";
          user = "sub0-assistants-aurora";
          group = "sub0-assistants-aurora";
          mode = "0700";
        }
      ];
    };
}
