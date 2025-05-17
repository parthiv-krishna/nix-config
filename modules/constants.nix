{ lib, ... }:
let
  mkPortOption =
    name: port:
    lib.mkOption {
      type = lib.types.port;
      default = port;
      description = "Port for ${name} service";
      readOnly = true;
    };
in
{
  options.constants = {
    services = {
      caddy = {
        port = mkPortOption "Caddy" 2019;
      };

      authelia = {
        port = mkPortOption "Authelia" 9091;
      };

      actual = {
        port = mkPortOption "Actual" 5006;
      };

      jellyfin = {
        port = mkPortOption "Jellyfin" 8096;
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
