{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.custom.discord-notifiers;

  # Create the Discord webhook script package
  discordWebhookScript = pkgs.writeShellApplication {
    name = "discord-webhook";
    runtimeInputs = with pkgs; [ python3Packages.discordpy ];
    text = ''
      exec ${pkgs.python3}/bin/python3 ${./discord-webhook.py} "$@"
    '';
  };

  # helper function to create a notifier service
  mkNotifierService =
    name: notifierCfg:
    let
      webhookScript = pkgs.writeShellScript "discord-notifier-${name}" ''
        set -o pipefail

        # Read webhook URL from secret file
        WEBHOOK_URL="$(cat "${notifierCfg.webhookSecretPath}")"

        ${discordWebhookScript}/bin/discord-webhook \
          "$WEBHOOK_URL" \
          --service "${notifierCfg.watchedService}" \
          --hostname "${config.networking.hostName}"
      '';
    in
    {
      "discord-notifier-${name}" = {
        description = "Discord notifier for ${notifierCfg.watchedService}";
        after = [ "${notifierCfg.watchedService}.service" ];
        bindsTo = [ "${notifierCfg.watchedService}.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${webhookScript}";
          User = "root"; # needed to read secret files
        };
      };
    };

  # generate all notifier services
  notifierServices = lib.mkMerge (
    lib.mapAttrsToList (
      name: notifierCfg: lib.mkIf notifierCfg.enable (mkNotifierService name notifierCfg)
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
