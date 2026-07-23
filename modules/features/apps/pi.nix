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

        settings = {
          defaultProvider = "litellm";
          defaultModel = "openai/openai/gpt-5.6-sol";
          defaultThinkingLevel = "medium";

          enableInstallTelemetry = false;

          packages = map toString (builtins.attrValues plugins);

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
    };
}
