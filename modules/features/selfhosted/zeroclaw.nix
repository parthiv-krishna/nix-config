# ZeroClaw - personal and media assistants
{ lib, inputs }:
let
  port = 42617;
  dataDir = "/var/lib/zeroclaw-assistant";
  user = "zeroclaw-assistant";
  signalDataDir = "/var/lib/zeroclaw-signal-cli";
  signalUser = "zeroclaw-signal";
in
lib.custom.mkSelfHostedFeature {
  name = "zeroclaw";
  subdomain = "assistant";
  inherit port;
  statusPath = "/health";
  backupServices = [
    "zeroclaw-assistant.service"
    "zeroclaw-signal-cli.service"
  ];

  extraOptions = {
    model = lib.mkOption {
      type = lib.types.str;
      default = "qwen3.8-flash-next";
      description = "Model served by the OpenAI-compatible inference endpoint";
    };
    endpoint = lib.mkOption {
      type = lib.types.str;
      default = "https://llm.sub0.net/v1";
      description = "OpenAI-compatible inference API base URL";
    };
  };

  homepage = categories: {
    category = categories.tools;
    description = "Personal AI assistant";
    icon = "mdi-robot";
  };

  persistentDirectories = [
    {
      directory = dataDir;
      inherit user;
      group = user;
      mode = "0750";
    }
    {
      directory = signalDataDir;
      user = signalUser;
      group = signalUser;
      mode = "0700";
    }
  ];

  serviceConfig =
    cfg:
    { config, pkgs, ... }:
    let
      packages = inputs.zeroclaw.packages.${pkgs.stdenv.hostPlatform.system};
      instance = config.services.zeroclaw.instances.assistant;
      configTemplate = (pkgs.formats.toml { }).generate "zeroclaw-assistant.toml" instance.settings;
      python = pkgs.python3.withPackages (ps: [ ps.toml ]);
      assistantPhoneSecret = "zeroclaw/signal/assistant_phone";
      userPhoneSecret = "zeroclaw/signal/user_phone";
      privateGroupSecret = "zeroclaw/signal/private_group_id";
      mediaGroupSecret = "zeroclaw/signal/media_group_id";
      seerrApiKeySecret = "zeroclaw/seerr/api_key";
      seerrMcp = pkgs.callPackage (lib.custom.relativeToRoot "packages/seerr-mcp-server") { };
      seerrMcpWrapper = pkgs.writeShellApplication {
        name = "zeroclaw-seerr-mcp";
        text = ''
          # Read credentials at runtime.
          JELLYSEERR_API_KEY="$(< ${lib.escapeShellArg config.sops.secrets.${seerrApiKeySecret}.path})"
          if [[ -z "$JELLYSEERR_API_KEY" ]]; then
            echo "Seerr MCP API key is empty" >&2
            exit 1
          fi
          export JELLYSEERR_API_KEY
          export JELLYSEERR_URL="http://127.0.0.1:5055"
          # Don't log searches or load .env files.
          export LOG_LEVEL=CRITICAL PYTHON_DOTENV_DISABLED=1
          exec ${lib.getExe seerrMcp}
        '';
      };
      # Preserve pairing tokens when rendering declarative config.
      renderConfig = pkgs.writeScript "zeroclaw-assistant-render-config" ''
        #!${python}/bin/python3
        import base64
        import os
        import re
        from pathlib import Path
        import toml

        def read_phone(path):
            phone = Path(path).read_text().strip()
            if not re.fullmatch(r"\+[1-9][0-9]{1,14}", phone):
                raise ValueError("Signal phone secret must be an E.164 number")
            return phone

        def read_group_id(path):
            group_id = Path(path).read_text().strip()
            try:
                decoded = base64.b64decode(group_id, validate=True)
            except ValueError:
                raise ValueError("Signal group secret must be a base64-encoded 32-byte ID") from None
            if len(decoded) != 32:
                raise ValueError("Signal group secret must be a base64-encoded 32-byte ID")
            return group_id

        target = Path("${dataDir}/config.toml")
        settings = toml.load("${configTemplate}")
        # Keep Signal identifiers out of the store.
        assistant_phone = read_phone("${config.sops.secrets.${assistantPhoneSecret}.path}")
        for alias in ("personal", "media"):
            settings["channels"]["signal"][alias]["account"] = assistant_phone
        settings["peer_groups"]["signal-owner"]["external_peers"] = [read_phone("${
          config.sops.secrets.${userPhoneSecret}.path
        }")]
        settings["channels"]["signal"]["personal"]["group_ids"] = [read_group_id("${
          config.sops.secrets.${privateGroupSecret}.path
        }")]
        settings["channels"]["signal"]["media"]["group_ids"] = [read_group_id("${
          config.sops.secrets.${mediaGroupSecret}.path
        }")]
        if target.exists():
            previous = toml.load(target)
            settings["gateway"]["paired_tokens"] = previous.get("gateway", {}).get("paired_tokens", [])
        temporary = target.with_suffix(".toml.tmp")
        with temporary.open("w") as output:
            toml.dump(settings, output)
        temporary.chmod(0o600)
        os.replace(temporary, target)
      '';
      # Keep local admin routes off the proxy.
      proxyConfig = ''
        tls {
          dns cloudflare {env.CF_API_TOKEN}
        }
        @localOnly path /admin /admin/* /pair/code
        respond @localOnly 403
        reverse_proxy 127.0.0.1:${toString port}
      '';
    in
    {
      services.zeroclaw.instances.assistant = {
        package = pkgs.callPackage (lib.custom.relativeToRoot "packages/zeroclaw") {
          inherit lib inputs;
        };
        webUiPackage = packages.zeroclaw-web;
        inherit dataDir user;
        group = user;
        settings = {
          schema_version = 3;
          providers.models.custom.sub0 = {
            uri = cfg.endpoint;
            inherit (cfg) model;
            wire_api = "chat_completions";
            # Custom endpoints default to text-fallback.
            native_tools = true;
          };
          agents.default = {
            enabled = true;
            channels = [ "signal.personal" ];
            skill_bundles = [ "personal" ];
            model_provider = "custom.sub0";
            risk_profile = "default";
            runtime_profile = "default";
            workspace.path = "${dataDir}/workspace";
          };
          agents.media = {
            enabled = true;
            channels = [ "signal.media" ];
            skill_bundles = [ "media" ];
            model_provider = "custom.sub0";
            mcp_bundles = [ "seerr" ];
            risk_profile = "media";
            runtime_profile = "default";
            workspace.path = "${dataDir}/workspace-media";
          };
          risk_profiles.default = {
            level = "supervised";
            workspace_only = true;
          };
          risk_profiles.media = {
            level = "supervised";
            workspace_only = true;
            # Block built-ins; granted MCP tools are auto-admitted.
            allowed_tools = [ "seerr__search_media" ];
            # Block arbitrary Seerr API access.
            excluded_tools = [ "seerr__raw_request" ];
            # Confirmation lives in the media skill.
            auto_approve = [
              "seerr__search_media"
              "seerr__request_media"
              "seerr__get_request"
              "seerr__ping"
            ];
          };
          mcp = {
            enabled = true;
            deferred_loading = false;
            servers = [
              {
                name = "seerr";
                transport = "stdio";
                command = lib.getExe seerrMcpWrapper;
              }
            ];
          };
          mcp_bundles.seerr.servers = [ "seerr" ];
          # Skill files are managed through the UI.
          skill_bundles = {
            personal.directory = "${dataDir}/shared/skills/personal";
            media.directory = "${dataDir}/shared/skills/media";
          };
          runtime_profiles.default = { };
          channels.signal.personal = {
            enabled = true;
            http_url = "http://127.0.0.1:8686";
            account = "$SIGNAL_ASSISTANT_PHONE";
            group_ids = [ "$SIGNAL_PRIVATE_GROUP_ID" ];
            group_only = true;
            dm_unsupported_notice = true;
            ignore_stories = true;
          };
          channels.signal.media = {
            enabled = true;
            http_url = "http://127.0.0.1:8686";
            account = "$SIGNAL_ASSISTANT_PHONE";
            group_ids = [ "$SIGNAL_MEDIA_GROUP_ID" ];
            group_only = true;
            ignore_stories = true;
          };
          peer_groups.signal-owner = {
            channel = "signal.personal";
            agents = [ "default" ];
            external_peers = [ "$SIGNAL_USER_PHONE" ];
          };
          peer_groups.signal-media = {
            channel = "signal.media";
            agents = [ "media" ];
            external_peers = [ "*" ];
          };
          gateway = {
            inherit port;
            host = "127.0.0.1";
            require_pairing = true;
            allow_public_bind = false;
            allow_remote_admin = false;
            trust_forwarded_headers = true;
            allow_self_upgrade = false;
            web_dist_dir = "${packages.zeroclaw-web}/share/zeroclaw-web";
          };
        };
      };

      sops.secrets =
        lib.genAttrs
          [
            assistantPhoneSecret
            userPhoneSecret
            privateGroupSecret
            mediaGroupSecret
            seerrApiKeySecret
          ]
          (_: {
            owner = user;
            group = user;
            mode = "0400";
            restartUnits = [ "zeroclaw-assistant.service" ];
          });

      # Stop signal-cli before registering or linking accounts.
      environment.systemPackages = [ pkgs.signal-cli ];
      users.users.${signalUser} = {
        isSystemUser = true;
        group = signalUser;
        home = signalDataDir;
      };
      users.groups.${signalUser} = { };

      systemd = {
        # Create bundle directories without replacing skill files.
        tmpfiles.rules = [
          "d ${dataDir}/shared 0750 ${user} ${user} -"
          "d ${dataDir}/shared/skills 0750 ${user} ${user} -"
          "d ${dataDir}/shared/skills/personal 0700 ${user} ${user} -"
          "d ${dataDir}/shared/skills/media 0700 ${user} ${user} -"
        ];

        services.zeroclaw-assistant = {
          wants = [ "zeroclaw-signal-cli.service" ];
          after = [ "zeroclaw-signal-cli.service" ];
          serviceConfig.ExecStartPre = lib.mkForce [ renderConfig ];
        };

        services.zeroclaw-signal-cli = {
          description = "Signal CLI HTTP daemon for ZeroClaw";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          environment.HOME = signalDataDir;
          serviceConfig = {
            # Keep message contents out of journald.
            ExecStart = "${lib.getExe pkgs.signal-cli} --data-dir ${signalDataDir} --scrub-log daemon --http 127.0.0.1:8686 --no-receive-stdout";
            User = signalUser;
            Group = signalUser;
            StateDirectory = "zeroclaw-signal-cli";
            StateDirectoryMode = "0700";
            WorkingDirectory = signalDataDir;
            Restart = "on-failure";
            RestartSec = "10s";
            UMask = "0077";
            NoNewPrivileges = true;
            PrivateTmp = true;
            PrivateDevices = true;
            ProtectSystem = "strict";
            ProtectHome = true;
            ProtectKernelTunables = true;
            ProtectKernelModules = true;
            ProtectKernelLogs = true;
            ProtectControlGroups = true;
            RestrictSUIDSGID = true;
            RestrictAddressFamilies = [
              "AF_INET"
              "AF_INET6"
              "AF_UNIX"
            ];
            CapabilityBoundingSet = "";
          };
        };
      };

      services.caddy.virtualHosts = {
        ${lib.custom.mkPublicFqdn config.constants "assistant"}.extraConfig = lib.mkForce proxyConfig;
        ${lib.custom.mkInternalFqdn config.constants "assistant" config.networking.hostName}.extraConfig =
          lib.mkForce proxyConfig;
      };
    };
}
