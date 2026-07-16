{ lib }:
let
  reasoningVariants = {
    low.reasoning_effort = "low";
    medium.reasoning_effort = "medium";
    high.reasoning_effort = "high";
    off.reasoning_effort = "none";
    xhigh.reasoning_effort = "xhigh";
  };
in
lib.custom.mkFeature {
  path = [
    "apps"
    "opencode"
  ];

  homeConfig = _cfg: _: {
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
              "claude-opus-4.8" = {
                id = "aws/anthropic/bedrock-claude-opus-4-8";
                name = "Claude Opus 4.8";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-sonnet-5" = {
                id = "aws/anthropic/bedrock-claude-sonnet-5";
                name = "Claude Sonnet 5";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-haiku-4.5" = {
                id = "aws/anthropic/claude-haiku-4-5-v1";
                name = "Claude Haiku 4.5";
              };

              "gpt-5.6-sol" = {
                id = "openai/openai/gpt-5.6-sol";
                name = "GPT 5.6 Sol";
                reasoning = true;
                variants = reasoningVariants;
              };

              "gpt-5.6-terra" = {
                id = "openai/openai/gpt-5.6-terra";
                name = "GPT 5.6 Terra";
                reasoning = true;
                variants = reasoningVariants;
              };

              "gpt-5.6-luna" = {
                id = "openai/openai/gpt-5.6-luna";
                name = "GPT 5.6 Luna";
                reasoning = true;
                variants = reasoningVariants;
              };
            };
          };
        };

        enabled_providers = [
          "openai"
          "nvidia" # build.nvidia.com
          "nvidia-internal" # inference.nvidia.com
        ];

        model = "nvidia-internal/gpt-5.6-terra";
        small_model = "nvidia-internal/gpt-5.6-luna";

        skills.paths = [ ".agents/skills" ];

        autoupdate = false;
        share = "disabled";
      };
    };

    custom.features.meta.impermanence.directories = [ ".local/share/opencode" ];
  };
}
