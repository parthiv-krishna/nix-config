{
  config,
  ...
}:
let
  dataDir = "/var/lib/traefik";
in
{
  services.traefik = {
    enable = true;
    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          http.redirections.entryPoint = {
            to = "websecure";
            scheme = "https";
          };
        };
        websecure = {
          address = ":443";
          http.tls.certResolver = "letsencrypt-staging";
        };
      };
      certificatesResolvers."letsencrypt-staging".acme = {
        storage = "${dataDir}/acme.json";
        caServer = "https://acme-staging-v02.api.letsencrypt.org/directory";
        dnsChallenge = {
          provider = "cloudflare";
          resolvers = [
            "1.0.0.1:53"
            "1.1.1.1:53"
          ];
          propagation.delayBeforeChecks = 120;
        };
      };
      log = {
        level = "INFO";
        filePath = "${dataDir}/traefik.log";
        format = "json";
      };
    };
    dynamicConfigOptions = {
      http = {
        routers."helloworld" = {
          rule = "Host(\`midnight.local.sub0.net\`)";
          entryPoints = [ "websecure" ];
          tls = true;
          service = "helloworld";
        };
        services."helloworld".loadBalancer.servers = [ { url = "http://localhost:81"; } ];
      };
    };
  };

  systemd.services.traefik.environment = {
    CF_DNS_API_TOKEN_FILE = config.sops.secrets."cloudflare/api_token".path;
  };

  networking.firewall.allowedTCPPorts = [
    80
    443
  ];

  environment.persistence."/persist/system" = {
    directories = [
      dataDir
    ];
  };
}
