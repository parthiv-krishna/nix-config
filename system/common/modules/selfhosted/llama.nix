{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (config.constants) hosts;
  port = 11434;
  llama-cpp = pkgs.llama-cpp.override {
    cudaSupport = true; # gpu acceleration
    blasSupport = true; # cpu acceleration
  };
  llama-server = lib.getExe' llama-cpp "llama-server";

  # model should be a path to the model
  # ngl should be # of GPU layers
  # all other attrs get passed through to the settings for that one
  modelConfigs = {
    ministral-3-14b-q4_k_m = {
      model = pkgs.fetchurl {
        url = "https://huggingface.co/unsloth/Ministral-3-14B-Instruct-2512-GGUF/resolve/main/Ministral-3-14B-Instruct-2512-Q4_K_M.gguf";
        hash = "sha256-ds5pfAZfLkDx6OlYEYsCyrOOLBCmAV99eQgDaiktyMg=";
      };
      ngl = 41;
      aliases = [
        "ministral-3-14b"
      ];
    };
  };
in
lib.custom.mkSelfHostedService {
  inherit
    config
    lib
    ;
  name = "llama-swap";
  inherit port;
  host = hosts.midnight;
  subdomain = "llm";
  serviceConfig = {
    services.llama-swap = {
      enable = true;
      # allow remote access (via reverse proxy)
      inherit port;
      listenAddress = "0.0.0.0";

      settings = {
        healthCheckTimeout = 60;
        # pass thru all other parameters as-is to the settings
        models = lib.mapAttrs (
          _name:
          { model, ngl, ... }@params:
          {
            cmd = "${llama-server} --port \${PORT} -m ${model} -ngl ${toString ngl} --no-webui";
          }
          // params
        ) modelConfigs;
      };
    };
  };

}
