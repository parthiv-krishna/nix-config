{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.custom.discord-notifiers;

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
      exec ${pythonWithDiscord}/bin/python3 ${./discord-webhook.py} "$@"
    '';
  };

  # helper function to create a notifier service
  mkNotifierService =
    name: notifierCfg:
    let
      mkWebhookScript =
        successFlag:
        pkgs.writeShellScript "discord-notifier-${name}-${if successFlag then "success" else "failure"}" ''
          set -o pipefail

          # Read webhook URL from secret file
          WEBHOOK_URL="$(cat "${notifierCfg.webhookSecretPath}")"

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
  notifierServices = lib.mkMerge (
    lib.mapAttrsToList (
      name: notifierCfg:
      lib.mkIf notifierCfg.enable (
        lib.mkMerge [
          (mkNotifierService name notifierCfg)
          {
            "${notifierCfg.watchedService}" = {
              onSuccess = [ "discord-notifier-${name}-success.service" ];
              onFailure = [ "discord-notifier-${name}-failure.service" ];
            };
          }
        ]
      )
    ) cfg
  );
in
{
  options.custom.discord-notifiers = lib.mkOption {
    type = lib.types.attrsOf (
      lib.types.submodule (
        { name, ... }:
        {
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
              default = config.sops.secrets."discord/webhook".path;
              description = "Path to file containing Discord webhook URL";
              example = "/run/secrets/discord-webhook";
            };
          };
        }
      )
    );
    default = { };
    description = "Discord notifiers that attach to systemd services";
  };

  config = lib.mkIf (cfg != { }) {
    systemd.services = notifierServices;
    sops.secrets."discord/webhook" = { };
  };
}
