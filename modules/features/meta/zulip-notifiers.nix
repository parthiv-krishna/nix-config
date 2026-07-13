{ lib }:
let
  # Define the notifier submodule type here so mkFeature can use it in extraOptions
  notifierSubmodule = lib.types.submodule (
    { name, ... }:
    {
      options = {
        enable = lib.mkEnableOption "this Zulip notifier";

        watchedService = lib.mkOption {
          type = lib.types.str;
          default = name;
          description = "Name of the systemd service to watch (without .service suffix). Defaults to the notifier name.";
          example = "auto-upgrade";
        };
      };
    }
  );
in
lib.custom.mkFeature {
  path = [
    "meta"
    "zulip-notifiers"
  ];

  extraOptions = {
    notifiers = lib.mkOption {
      type = lib.types.attrsOf notifierSubmodule;
      default = { };
      description = "Zulip notifiers that attach to systemd services";
    };

    channel = lib.mkOption {
      type = lib.types.str;
      default = "alerts";
      description = "Zulip channel (stream) to post notifications to";
    };

    summarizeFailures = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        On failure notifications, summarize the service logs via a direct
        OpenAI-compatible chat completion (see summarizerApiUrl/summarizerModel)
        and include a brief likely-cause summary in the Zulip message. Requires
        the `zulip/build_nvidia_api_key` secret.
      '';
    };

    summarizerApiUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://integrate.api.nvidia.com/v1";
      description = "OpenAI-compatible base URL used to summarize failure logs";
    };

    summarizerModel = lib.mkOption {
      type = lib.types.str;
      default = "nvidia/nemotron-3-super-120b-a12b";
      description = "Model id used to summarize failure logs";
    };
  };

  systemConfig =
    cfg:
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      notifiersCfg = cfg.notifiers;

      # Create the Zulip notify script package
      pythonWithRequests = pkgs.python3.withPackages (
        ps: with ps; [
          requests
        ]
      );
      zulipNotifyScript = pkgs.writeShellApplication {
        name = "zulip-notify";
        runtimeInputs = [ pythonWithRequests ];
        text = ''
          exec ${pythonWithRequests}/bin/python3 ${lib.custom.relativeToRoot "scripts/zulip-notify.py"} "$@"
        '';
      };

      webhookUrlPath = config.sops.secrets."zulip/webhook".path;
      summarizerKeyPath = config.sops.secrets."zulip/build_nvidia_api_key".path;

      # helper function to create a notifier service
      mkNotifierService =
        name: notifierCfg:
        let
          mkNotifyScript =
            successFlag:
            pkgs.writeShellScript "zulip-notifier-${name}-${if successFlag then "success" else "failure"}" ''
              set -o pipefail

              # Read Zulip incoming webhook URL from secret file
              WEBHOOK_URL="$(cat "${webhookUrlPath}")"

              ${lib.optionalString (cfg.summarizeFailures && !successFlag) ''
                # summarizer API key passed via env (not argv) to keep it out of ps
                SUMMARIZER_API_KEY="$(cat "${summarizerKeyPath}")"
                export SUMMARIZER_API_KEY
              ''}

              ${zulipNotifyScript}/bin/zulip-notify \
                --webhook-url "$WEBHOOK_URL" \
                --channel "${cfg.channel}" \
                --service "${notifierCfg.watchedService}" \
                --hostname "${config.networking.hostName}" \
                ${lib.optionalString (cfg.summarizeFailures && !successFlag) ''
                  --summarizer-api-url "${cfg.summarizerApiUrl}" \
                  --summarizer-model "${cfg.summarizerModel}" \
                ''}
                ${if successFlag then "" else "--failure"}
            '';
          successScript = mkNotifyScript true;
          failureScript = mkNotifyScript false;
        in
        {
          "zulip-notifier-${name}-success" = {
            description = "Zulip notifier for ${notifierCfg.watchedService} success";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${successScript}";
              User = "root"; # needed to read secret files
            };
          };
          "zulip-notifier-${name}-failure" = {
            description = "Zulip notifier for ${notifierCfg.watchedService} failure";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${failureScript}";
              User = "root"; # needed to read secret files
            };
          };
        };

      # generate all notifier services and bind them to watched services
      enabledNotifiers = lib.filterAttrs (_: n: n.enable) notifiersCfg;
      notifierServices = lib.mkMerge (
        lib.mapAttrsToList (
          name: notifierCfg:
          lib.mkMerge [
            (mkNotifierService name notifierCfg)
            {
              "${notifierCfg.watchedService}" = {
                onSuccess = [ "zulip-notifier-${name}-success.service" ];
                onFailure = [ "zulip-notifier-${name}-failure.service" ];
              };
            }
          ]
        ) enabledNotifiers
      );
    in
    lib.mkIf (enabledNotifiers != { }) {
      systemd.services = notifierServices;

      sops.secrets = {
        "zulip/webhook" = { };
      }
      // lib.optionalAttrs cfg.summarizeFailures {
        "zulip/build_nvidia_api_key" = { };
      };
    };
}
