# OpenCode LLM agent feature - home-only
{ lib }:
let
  reasoningVariants = {
    low.reasoning_effort = "low";
    medium.reasoning_effort = "medium";
    high.reasoning_effort = "high";
    off.reasoning_effort = "none";
  };

  # MCP plugin configurations
  mcp = import ./mcp { inherit lib; };
in
lib.custom.mkFeature {
  path = [ "apps" "opencode" ];

  homeConfig = cfg: { pkgs, ... }: {
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
              "claude-opus-4.5" = {
                id = "aws/anthropic/claude-opus-4-5";
                name = "Claude 4.5 Opus";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-sonnet-4.5" = {
                id = "aws/anthropic/bedrock-claude-sonnet-4-5-v1";
                name = "Claude 4.5 Sonnet";
                reasoning = true;
                variants = reasoningVariants;
              };

              "claude-haiku-4.5" = {
                id = "aws/anthropic/claude-haiku-4-5-v1";
                name = "Claude Haiku 4.5";
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

        model = "nvidia-internal/claude-opus-4.5";
        small_model = "nvidia-internal/claude-haiku-4.5";

        autoupdate = false;
        share = "disabled";

        # MCP plugins
        mcp = mcp.mkMcpConfig pkgs;
      };
    };

    custom.persistence.directories = [ ".local/share/opencode" ];
  };
}
