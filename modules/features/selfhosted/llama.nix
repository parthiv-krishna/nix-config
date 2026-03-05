# Llama-swap - LLM serving with model swapping
{ lib }:
lib.custom.mkSelfHostedFeature {
  name = "llama-swap";
  subdomain = "llm";
  port = 11434;

  serviceConfig =
    _cfg:
    { lib, pkgs, ... }:
    let
      llama-cpp = pkgs.llama-cpp.override {
        cudaSupport = true;
        blasSupport = true;
      };
      llama-server = lib.getExe' llama-cpp "llama-server";

      modelConfigs = {
        gemma3n-e2b-iq2_xxs = {
          model = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/gemma-3n-E2B-it-GGUF/resolve/main/gemma-3n-E2B-it-UD-Q3_K_XL.gguf";
            hash = "sha256-YvulfJBsMS/2zHobvwzUlSNJPfWfr4yyZoReBGoBZgA=";
          };
          ngl = 0;
          extraArgs = "--device none";
          aliases = [
            "gemma3n"
            "gemma3n-e2b"
            "small"
          ];
        };
        ministral3-14b-q4_k_m = {
          model = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Ministral-3-14B-Instruct-2512-GGUF/resolve/main/Ministral-3-14B-Instruct-2512-Q4_K_M.gguf";
            hash = "sha256-ds5pfAZfLkDx6OlYEYsCyrOOLBCmAV99eQgDaiktyMg=";
          };
          ngl = 41;
          aliases = [
            "ministral3"
            "ministral3-14b"
            "large"
          ];
        };
        qwen3vl-8b-thinking-q4_k_m = {
          model = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3-VL-8B-Thinking-GGUF/resolve/main/Qwen3-VL-8B-Thinking-Q4_K_M.gguf";
            hash = "sha256-o2bG1+YwwHwTk9KVVd9nJ4+evUDC/WqAZZAl/ymdAyc=";
          };
          ngl = 37;
          ctxSize = 36864;
          aliases = [
            "qwen3vl-thinking"
            "qwen3vl-8b-thinking"
            "thinking"
            "vision"
          ];
          mmproj = pkgs.fetchurl {
            url = "https://huggingface.co/unsloth/Qwen3-VL-8B-Thinking-GGUF/resolve/main/mmproj-BF16.gguf";
            hash = "sha256-4G/N2omMCeprseyktIH8bB55PTTvMaCtEoZ4t2PshoI=";
          };
        };
      };
    in
    {
      services.llama-swap = {
        enable = true;
        port = 11434;
        listenAddress = "0.0.0.0";

        settings = {
          healthCheckTimeout = 60;

          groups = {
            gpu_models = {
              swap = true;
              exclusive = true;
              members = [
                "ministral3-14b-q4_k_m"
                "qwen3vl-8b-thinking-q4_k_m"
              ];
            };
            cpu_model = {
              swap = false;
              exclusive = false;
              persistent = true;
              members = [ "gemma3n-e2b-iq2_xxs" ];
            };
          };

          models = lib.mapAttrs (
            _name:
            {
              model,
              ngl,
              mmproj ? null,
              ctxSize ? null,
              extraArgs ? "",
              ...
            }@params:
            let
              mmprojArgs = if (mmproj == null) then "" else "--mmproj ${mmproj}";
              ctxSizeArgs = if (ctxSize == null) then "" else "--ctx-size ${toString ctxSize}";
            in
            {
              cmd = "${llama-server} --port \${PORT} -m ${model} ${mmprojArgs} ${ctxSizeArgs} -ngl ${toString ngl} --no-webui ${extraArgs}";
              ttl = 300;
            }
            // params
          ) modelConfigs;
        };
      };
    };
}
