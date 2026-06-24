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
                name = "Claude 4.8 Opus";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-sonnet-4.6" = {
                id = "aws/anthropic/bedrock-claude-sonnet-4-6";
                name = "Claude 4.6 Sonnet";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-haiku-4.5" = {
                id = "aws/anthropic/claude-haiku-4-5-v1";
                name = "Claude Haiku 4.5";
              };

              "gpt-5.5" = {
                id = "openai/openai/gpt-5.5";
                name = "GPT 5.5";
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

        model = "nvidia-internal/gpt-5.5";
        small_model = "nvidia-internal/claude-haiku-4.5";

        skills.paths = [ ".agents/skills" ];

        autoupdate = false;
        share = "disabled";
      };
    };

    custom.features.meta.impermanence.directories = [ ".local/share/opencode" ];
  };
}
