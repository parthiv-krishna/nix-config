{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "pi"
  ];

  homeConfig =
    _cfg:
    { config, pkgs, ... }:
    let
      plugins = {
        provider-litellm = pkgs.fetchzip {
          name = "pi-provider-litellm-1.3.0";
          url = "https://registry.npmjs.org/pi-provider-litellm/-/pi-provider-litellm-1.3.0.tgz";
          hash = "sha256-dq4QjOCBQh2GIFf6LpyCvKXb+X69McLGz5DLw7A5oF4=";
        };
      };

      # agent client protocol adapter for pi to drive over stdio
      pi-acp = pkgs.buildNpmPackage rec {
        pname = "pi-acp";
        version = "0.0.34";
        src = pkgs.fetchFromGitHub {
          owner = "svkozak";
          repo = "pi-acp";
          tag = "v${version}";
          hash = "sha256-QRwxOtTZOY+Np3PkAoy2o2PrUzEqjItM/372sCPlSMo=";
        };
        npmDepsHash = "sha256-BvLNtFfp1cMVjzWcMRSdhTqiJrTfbFoUbWkkPW9200o=";
        meta = {
          description = "ACP adapter for the pi coding agent";
          homepage = "https://github.com/svkozak/pi-acp";
          license = lib.licenses.mit;
          mainProgram = "pi-acp";
        };
      };
    in
    {
      programs.pi-coding-agent = {
        enable = true;
        extraPackages = [ pkgs.nodejs ];

        models.providers = {
          openai-codex.modelOverrides = {
            "gpt-6.1-sol".contextWindow = 872000;
            "gpt-6-luna".contextWindow = 872000;
            "gpt-6-astra".contextWindow = 872000;
          };

          sub0 = {
            baseUrl = "${lib.custom.mkPublicHttpsUrl config.constants "llm"}/v1";
            api = "openai-completions";
            apiKey = "sub0";
            compat = {
              supportsDeveloperRole = false;
              supportsReasoningEffort = false;
              thinkingFormat = "qwen-chat-template";
            };
            models = [
              {
                id = "qwen3.8-flash-next";
                name = "Qwen 3.8 Flash Next";
                reasoning = true;
                contextWindow = 262144;
                maxTokens = 32768;
              }
            ];
          };
        };

        settings = {
          defaultProvider = "openai-codex";
          defaultModel = "gpt-6.1-sol";
          defaultThinkingLevel = "medium";

          enableInstallTelemetry = false;

          packages = [
            {
              source = "npm:pi-background-tasks@2.5.0";
              extensions = [ "-extensions/anthropic-attribution.ts" ];
            }
            "npm:pi-intercom@0.13.0"
            "npm:@narumitw/pi-goal@0.54.4"
            "npm:pi-lens@4.1.5"
            "npm:@gotgenes/pi-permission-system@31.1.3"
            "npm:pi-subagents@0.67.0"
            "npm:threadroom-pi@0.1.0-beta.0"
            "npm:pi-tmux-session-map@0.4.0"
            "npm:pi-vimmode@0.9.0"
            "npm:pi-web-access@0.28.0"
          ]
          ++ map toString (builtins.attrValues plugins);

          litellm = {
            providers.litellm = {
              baseUrl = "https://inference-api.nvidia.com";
              displayName = "NVIDIA Internal";
            };

            mcp.enabled = false;
            skills.enabled = false;
          };
        };
      };

      home.packages = [ pi-acp ];

      custom.features.meta.impermanence.directories = [
        ".local/state/pi/tmux-sessions"
        ".pi/agent"
      ];

      programs.git.ignores = [
        ".pi"
        ".pi-subagents"
      ];
    };
}
