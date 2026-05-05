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
              "claude-haiku-4.5" = {
                id = "aws/anthropic/claude-haiku-4-5-v1";
                name = "Claude Haiku 4.5";
              };

              "claude-opus-4.6" = {
                id = "aws/anthropic/bedrock-claude-opus-4-6";
                name = "Claude 4.7 Opus";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-opus-4.7" = {
                id = "aws/anthropic/claude-opus-4-7";
                name = "Claude 4.7 Opus";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-sonnet-4.6" = {
                id = "aws/anthropic/bedrock-claude-sonnet-4-6";
                name = "Claude 4.6 Sonnet";
                reasoning = true;
                variants = reasoningVariants;
              };

              "gemini-3-pro" = {
                id = "gcp/google/gemini-3-pro";
                name = "Gemini 3 Pro";
                reasoning = true;
                variants = reasoningVariants;
              };

              "gemini-3-flash" = {
                id = "gcp/google/gemini-3-flash-preview";
                name = "Gemini 3 Flash (preview)";
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
          "anthropic"
          "github-copilot"
          "openai"
          "nvidia" # build.nvidia.com
          "nvidia-internal" # inference.nvidia.com
        ];

        model = "nvidia-internal/gpt-5.5";
        small_model = "nvidia-internal/claude-haiku-4.5";

        autoupdate = false;
        share = "disabled";
      };
    };

    custom.features.meta.impermanence.directories = [ ".local/share/opencode" ];
  };
}
