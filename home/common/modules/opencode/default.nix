{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.opencode;
in
{
  options.custom.opencode = {
    enable = lib.mkEnableOption "opencode LLM agent";
  };

  imports = lib.custom.scanPaths ./.;

  config = lib.mkIf cfg.enable {
    programs.opencode = {
      enable = true;

      settings = {
        provider = {
          "nvidia" = {
            npm = "@ai-sdk/openai-compatible";
            name = "NVIDIA";
            options = {
              baseURL = "https://inference-api.nvidia.com/v1";
            };
          };
        };

        enabled_providers = [
          "anthropic"
          "github-copilot"
          "nvidia"
        ];

        autoupdate = false;
        share = "disabled";
      };
    };
  };
}
