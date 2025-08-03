_:
let
  # build FQDN with optional subdomain
  mkFqdn =
    baseDomain: subdomain: host:
    if subdomain == "" then
      if host == null then baseDomain else "${host}.${baseDomain}"
    else if host == null then
      "${subdomain}.${baseDomain}"
    else
      "${subdomain}.${host}.${baseDomain}";

  mkPublicFqdn = constants: subdomain: mkFqdn constants.domains.public subdomain null;

  mkInternalFqdn =
    constants: subdomain: host:
    mkFqdn constants.domains.internal subdomain host;

  # add HTTPS prefix
  addHttps = domain: "https://${domain}";
in
{
  inherit mkPublicFqdn mkInternalFqdn;

  mkPublicHttpsUrl = constants: subdomain: addHttps (mkPublicFqdn constants subdomain);

  mkInternalHttpsUrl =
    constants: subdomain: host:
    addHttps (mkInternalFqdn constants subdomain host);
}
