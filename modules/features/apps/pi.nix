{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "pi"
  ];

  homeConfig =
    _cfg:
    { pkgs, ... }:
    let
      plugins = {
        provider-litellm = pkgs.fetchzip {
          name = "pi-provider-litellm-1.3.0";
          url = "https://registry.npmjs.org/pi-provider-litellm/-/pi-provider-litellm-1.3.0.tgz";
          hash = "sha256-dq4QjOCBQh2GIFf6LpyCvKXb+X69McLGz5DLw7A5oF4=";
        };
      };
    in
    {
      programs.pi-coding-agent = {
        enable = true;
        extraPackages = [ pkgs.nodejs ];

        models.providers.openai-codex.modelOverrides = {
          "gpt-5.6-sol".contextWindow = 872000;
          "gpt-5.6-terra".contextWindow = 872000;
          "gpt-5.6-luna".contextWindow = 872000;
          "gpt-6-astra".contextWindow = 872000;
        };

        settings = {
          defaultProvider = "openai-codex";
          defaultModel = "gpt-5.6-sol";
          defaultThinkingLevel = "medium";

          enableInstallTelemetry = false;

          packages = [
            "npm:@juicesharp/rpiv-ask-user-question@2.9.0"
            "npm:pi-background-tasks@2.5.0"
            "npm:pi-intercom@0.13.0"
            "npm:@narumitw/pi-goal@0.54.4"
            "npm:pi-lens@4.1.5"
            "npm:@gotgenes/pi-permission-system@31.1.3"
            "npm:pi-subagents@0.67.0"
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

      custom.features.meta.impermanence.directories = [ ".pi/agent" ];

      programs.git.ignores = [ ".pi-subagents" ];
    };
}
