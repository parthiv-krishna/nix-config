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

        settings = {
          defaultProvider = "openai-codex";
          defaultModel = "gpt-5.6-sol";
          defaultThinkingLevel = "medium";

          enableInstallTelemetry = false;

          packages = [
            "npm:@juicesharp/rpiv-ask-user-question@2.1.0"
            "npm:pi-background-tasks@2.4.2"
            "npm:@narumitw/pi-goal@0.28.0"
            "npm:pi-lens@3.8.71"
            "npm:@gotgenes/pi-permission-system@21.0.0"
            "npm:pi-subagents@0.35.1"
            "npm:pi-vimmode@0.9.0"
            "npm:pi-web-access@0.13.0"
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
