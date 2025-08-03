_: {
  mkPublicFqdn = constants: subdomain: "${subdomain}.${constants.domains.public}";

  mkInternalFqdn =
    constants: subdomain: host:
    "${subdomain}.${host}.${constants.domains.internal}";
}
