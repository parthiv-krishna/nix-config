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
          nvidia-internal = {
            npm = "@ai-sdk/openai-compatible";
            name = "NVIDIA Internal";
            options = {
              baseURL = "https://inference-api.nvidia.com/v1";
            };
            models = {
              "claude-opus-4.5-high" = {
                id = "aws/anthropic/claude-opus-4-5";
                name = "Claude 4.5 Opus (high)";
                reasoning = true;
                options.reasoning_effort = "high";
              };
            };
          };
        };

        enabled_providers = [
          "anthropic"
          "github-copilot"
          "nvidia" # build.nvidia.com
          "nvidia-internal" # inference.nvidia.com
        ];

        autoupdate = false;
        share = "disabled";
      };
    };
  };
}
