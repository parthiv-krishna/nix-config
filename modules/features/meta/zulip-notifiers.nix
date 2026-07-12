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

    realmUrl = lib.mkOption {
      type = lib.types.str;
      default = "https://sub0.zulipchat.com";
      description = "Base URL of the Zulip realm to send notifications to";
      example = "https://sample.zulipchat.com";
    };

    channel = lib.mkOption {
      type = lib.types.str;
      default = "alerts";
      description = "Zulip channel (stream) to post notifications to";
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

      botEmailPath = config.sops.secrets."zulip/bot_email".path;
      apiKeyPath = config.sops.secrets."zulip/api_key".path;

      # helper function to create a notifier service
      mkNotifierService =
        name: notifierCfg:
        let
          mkNotifyScript =
            successFlag:
            pkgs.writeShellScript "zulip-notifier-${name}-${if successFlag then "success" else "failure"}" ''
              set -o pipefail

              # Read Zulip credentials from secret files
              BOT_EMAIL="$(cat "${botEmailPath}")"
              API_KEY="$(cat "${apiKeyPath}")"

              ${zulipNotifyScript}/bin/zulip-notify \
                --realm-url "${cfg.realmUrl}" \
                --bot-email "$BOT_EMAIL" \
                --api-key "$API_KEY" \
                --channel "${cfg.channel}" \
                --service "${notifierCfg.watchedService}" \
                --hostname "${config.networking.hostName}" \
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
      sops.secrets."zulip/bot_email" = { };
      sops.secrets."zulip/api_key" = { };
    };
}
