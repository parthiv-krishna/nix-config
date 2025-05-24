{ lib, ... }:
let
  mkPortOption =
    port:
    lib.mkOption {
      type = lib.types.port;
      default = port;
      readOnly = true;
    };
in
{
  options.constants = {
    services = {
      actual = {
        port = mkPortOption 5006;
      };

      authelia = {
        port = mkPortOption 9091;
        redis-port = mkPortOption 6379;
      };

      crowdsec = {
        port = mkPortOption 9090;
      };

      jellyfin = {
        port = mkPortOption 8096;
      };
    };

    proxyHostName = lib.mkOption {
      type = lib.types.str;
      default = "nimbus";
      description = "Hostname of the public-facing proxy server";
      readOnly = true;
    };

    domains = {
      public = lib.mkOption {
        type = lib.types.str;
        default = "sub0.net";
        description = "Public domain name";
        readOnly = true;
      };

      internal = lib.mkOption {
        type = lib.types.str;
        default = "ts.sub0.net";
        description = "Internal domain name";
        readOnly = true;
      };
    };
  };
}
