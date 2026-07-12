# VPN confinement - WireGuard network namespace for confining systemd services
{ lib }:
lib.custom.mkFeature {
  path = [
    "networking"
    "vpn"
  ];

  extraOptions = {
    namespace = lib.mkOption {
      type = lib.types.str;
      default = "vpn";
      description = "Network namespace used for VPN-confined services (limited to 7 characters).";
    };

    piaRegion = lib.mkOption {
      type = lib.types.str;
      default = "swiss";
      description = "PIA region id used when generating WireGuard credentials.";
    };

    confinedServices = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule { });
      default = { };
      description = ''
        Services confined to the VPN namespace, keyed by systemd unit name. They
        are reached from the default namespace through the namespace address (see
        reverse proxy config).
      '';
    };
  };

  # assertion needs to be unconditional so it fires when vpn is disabled
  systemConfigUnconditional =
    cfg:
    { lib, ... }:
    {
      assertions = [
        {
          assertion = cfg.confinedServices == { } || cfg.enable;
          message =
            "custom.features.networking.vpn.confinedServices is non-empty "
            + "(${lib.concatStringsSep ", " (lib.attrNames cfg.confinedServices)}) "
            + "but custom.features.networking.vpn.enable is false. "
            + "Enable the vpn feature to confine these services.";
        }
      ];
    };

  systemConfig =
    cfg:
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (cfg) namespace;
      wgConfigPath = "/run/vpn/wg_config";
      piaCa = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/pia-foss/manual-connections/master/ca.rsa.4096.crt";
        sha256 = "1av6dilvm696h7pb5xn91ibw0mrziqsnwk51y8a7da9y8g8v3s9j";
      };

      confinedServiceNames = lib.attrNames cfg.confinedServices;
      confinedSystemdServices = map (svc: "${svc}.service") confinedServiceNames;

      # PIA WireGuard config generation adapted from PIA's official manual-connections
      # scripts (https://github.com/pia-foss/manual-connections); see also
      # https://github.com/j00w33/pia-autoconnect-wireguard/blob/main/auto-connect.sh
      vpnConfig = pkgs.writeShellApplication {
        name = "vpn-config";
        runtimeInputs = with pkgs; [
          coreutils
          curl
          jq
          wireguard-tools
        ];
        text = ''
          set -euo pipefail
          umask 077

          curl_retry() {
            for attempt in $(seq 1 12); do
              if curl "$@"; then
                return 0
              fi
              echo "curl attempt $attempt failed; retrying..." >&2
              sleep 5
            done

            curl "$@"
          }

          username="$(tr -d '\n' < ${config.sops.secrets."vpn/pia_username".path})"
          password="$(tr -d '\n' < ${config.sops.secrets."vpn/pia_password".path})"

          token_response="$(curl_retry -fsSL --location --request POST \
            'https://www.privateinternetaccess.com/api/client/v2/token' \
            --form-string "username=$username" \
            --form-string "password=$password")"
          token="$(jq -er '.token' <<< "$token_response")"

          server_list="$(curl_retry -fsSL 'https://serverlist.piaservers.net/vpninfo/servers/v6' | head -n 1)"
          region_data="$(jq -er --arg region '${cfg.piaRegion}' '.regions[] | select(.id == $region)' <<< "$server_list")"
          wg_server_ip="$(jq -er '.servers.wg[0].ip' <<< "$region_data")"
          wg_hostname="$(jq -er '.servers.wg[0].cn' <<< "$region_data")"

          private_key="$(wg genkey)"
          public_key="$(printf '%s' "$private_key" | wg pubkey)"

          wireguard_json="$(curl_retry -fsSL -G \
            --connect-to "$wg_hostname::$wg_server_ip:" \
            --cacert '${piaCa}' \
            --data-urlencode "pt=$token" \
            --data-urlencode "pubkey=$public_key" \
            "https://$wg_hostname:1337/addKey")"

          if [[ "$(jq -r '.status' <<< "$wireguard_json")" != "OK" ]]; then
            echo "PIA WireGuard API did not return OK" >&2
            echo "$wireguard_json" >&2
            exit 1
          fi

          mkdir -p "$(dirname '${wgConfigPath}')"
          tmp="$(mktemp '${wgConfigPath}.XXXXXX')"
          cat > "$tmp" <<EOF
          [Interface]
          Address = $(jq -er '.peer_ip' <<< "$wireguard_json")
          PrivateKey = $private_key
          DNS = $(jq -er '.dns_servers | join(",")' <<< "$wireguard_json")

          [Peer]
          PersistentKeepalive = 25
          PublicKey = $(jq -er '.server_key' <<< "$wireguard_json")
          AllowedIPs = 0.0.0.0/0
          Endpoint = $wg_server_ip:$(jq -er '.server_port' <<< "$wireguard_json")
          EOF
          mv "$tmp" '${wgConfigPath}'
          echo "Generated PIA WireGuard config for ${cfg.piaRegion} ($wg_server_ip)."
        '';
      };

      vpnPostStart = pkgs.writeShellScript "vpn-post-start" ''
        ${pkgs.iproute2}/bin/ip netns exec ${namespace} ${pkgs.iproute2}/bin/ip link set ${namespace}0 mtu 1280

        while IFS= read -r ns; do
          ns="''${ns#nameserver }"
          if [[ $ns == *.* ]]; then
            ${pkgs.iproute2}/bin/ip -n ${namespace} route replace "$ns/32" dev ${namespace}0
          else
            ${pkgs.iproute2}/bin/ip -n ${namespace} -6 route replace "$ns/128" dev ${namespace}0
          fi
        done < /etc/netns/${namespace}/resolv.conf
      '';

      vpnTestScript = pkgs.writeShellApplication {
        name = "vpn-test";
        runtimeInputs = with pkgs; [
          bash
          curl
          iproute2
          unixtools.ping
        ];
        text = ''
          echo "Current wireguard interface config:"
          ip link show ${namespace}0

          echo "Current public IP:"
          curl -s ifconfig.me

          echo "Running DNS leak test:"
          bash ${lib.custom.relativeToRoot "scripts/dnsleaktest.sh"}
        '';
      };

      refreshScript = pkgs.writeShellScript "vpn-refresh" ''
        set -euo pipefail
        systemctl restart vpn-config.service
        systemctl restart ${namespace}.service
        systemctl restart ${lib.escapeShellArgs confinedSystemdServices}
        systemctl start vpn-test.service
      '';
    in
    {
      systemd = {
        services = {
          vpn-config = {
            description = "Generate PIA WireGuard config for vpn namespace";
            after = [
              "network-online.target"
              "nss-lookup.target"
              "sops-install-secrets.service"
            ];
            wants = [
              "network-online.target"
              "nss-lookup.target"
            ];
            requires = [ "sops-install-secrets.service" ];
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${vpnConfig}/bin/vpn-config";
            };
          };

          ${namespace} = {
            after = [ "vpn-config.service" ];
            requires = [ "vpn-config.service" ];
            serviceConfig.ExecStartPost = vpnPostStart;
          };

          vpn-test = {
            description = "Test VPN";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = "${vpnTestScript}/bin/vpn-test";
            };
            vpnConfinement = {
              enable = true;
              vpnNamespace = namespace;
            };
          };

          vpn-refresh = {
            description = "Refresh VPN";
            serviceConfig = {
              Type = "oneshot";
              ExecStart = refreshScript;
            };
          };
        }
        // lib.mapAttrs' (unitName: _svc: {
          name = unitName;
          value.vpnConfinement = {
            enable = true;
            vpnNamespace = namespace;
          };
        }) cfg.confinedServices;

        timers.vpn-refresh = {
          description = "Refresh wireguard every 12h";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnUnitActiveSec = "12h";
            Unit = "vpn-refresh.service";
          };
        };
      };

      vpnNamespaces.${namespace} = {
        enable = true;
        wireguardConfigFile = wgConfigPath;
        accessibleFrom = [ "127.0.0.1" ];
      };

      custom.features.meta.zulip-notifiers.notifiers = {
        vpn-config.enable = true;
        vpn-test.enable = true;
        vpn-refresh.enable = true;
      };

      sops.secrets = {
        "vpn/pia_username" = { };
        "vpn/pia_password" = { };
      };
    };
}
