# Service notifications via Discord - system-only
# This defines a submodule for each notifier
{ lib }:
let
  # Define the notifier submodule type here so mkFeature can use it in extraOptions
  notifierSubmodule = lib.types.submodule ({ name, config, ... }: {
    options = {
      enable = lib.mkEnableOption "this Discord notifier";

      watchedService = lib.mkOption {
        type = lib.types.str;
        default = name;
        description = "Name of the systemd service to watch (without .service suffix). Defaults to the notifier name.";
        example = "auto-upgrade";
      };

      webhookSecretPath = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Path to file containing Discord webhook URL";
        example = "/run/secrets/discord-webhook";
      };
    };
  });
in
lib.custom.mkFeature {
  path = [ "meta" "discord-notifiers" ];

  extraOptions = {
    notifiers = lib.mkOption {
      type = lib.types.attrsOf notifierSubmodule;
      default = { };
      description = "Discord notifiers that attach to systemd services";
    };
  };

  systemConfig = cfg: { config, pkgs, lib, ... }: 
    let
      notifiersCfg = cfg.notifiers;

      # Create the Discord webhook script package
      pythonWithDiscord = pkgs.python3.withPackages (
        ps: with ps; [
          discordpy
          requests
        ]
      );
      discordWebhookScript = pkgs.writeShellApplication {
        name = "discord-webhook";
        runtimeInputs = [ pythonWithDiscord ];
        text = ''
          exec ${pythonWithDiscord}/bin/python3 ${lib.custom.relativeToRoot "scripts/discord-webhook.py"} "$@"
        '';
      };

      # helper function to create a notifier service
      mkNotifierService =
        name: notifierCfg:
        let
          webhookPath = if notifierCfg.webhookSecretPath != "" 
            then notifierCfg.webhookSecretPath 
            else config.sops.secrets."discord/webhook".path;
          mkWebhookScript =
            successFlag:
            pkgs.writeShellScript "discord-notifier-${name}-${if successFlag then "success" else "failure"}" ''
              set -o pipefail

              # Read webhook URL from secret file
              WEBHOOK_URL="$(cat "${webhookPath}")"

              ${discordWebhookScript}/bin/discord-webhook \
                "$WEBHOOK_URL" \
                --service "${notifierCfg.watchedService}" \
                --hostname "${config.networking.hostName}" \
                ${if successFlag then "" else "--failure"}
            '';
          successScript = mkWebhookScript true;
          failureScript = mkWebhookScript false;
        in
        {
          "discord-notifier-${name}-success" = {
            description = "Discord notifier for ${notifierCfg.watchedService} success";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${successScript}";
              User = "root"; # needed to read secret files
            };
          };
          "discord-notifier-${name}-failure" = {
            description = "Discord notifier for ${notifierCfg.watchedService} failure";
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
                onSuccess = [ "discord-notifier-${name}-success.service" ];
                onFailure = [ "discord-notifier-${name}-failure.service" ];
              };
            }
          ]
        ) enabledNotifiers
      );
    in 
    lib.mkIf (enabledNotifiers != { }) {
      systemd.services = notifierServices;
      sops.secrets."discord/webhook" = { };
    };
}
