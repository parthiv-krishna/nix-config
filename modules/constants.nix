{ lib, ... }:
let
  mkConstant =
    type: value:
    lib.mkOption {
      inherit type;
      default = value;
      readOnly = true;
    };
  mkPortConstant = mkConstant lib.types.port;
  mkStringConstant = mkConstant lib.types.str;
in
{
  options.constants = {
    ports = {
      actual = mkPortConstant 5006;
      authelia = mkPortConstant 9091;
      authelia-redis = mkPortConstant 6379;
      crowdsec = mkPortConstant 9090;
      immich = mkPortConstant 2283;
      immich-redis = mkPortConstant 6378;
      jellyfin = mkPortConstant 8096;
      ollama = mkPortConstant 11434;
      thaw = mkPortConstant 8301;
    };

    proxyHostName = mkStringConstant "nimbus";

    domains = {
      public = mkStringConstant "sub0.net";
      internal = mkStringConstant "ts.sub0.net";
    };
    tieredCache = {
      cachePool = mkStringConstant "/array/merge/cache";
      basePool = mkStringConstant "/array/merge/base";
    };
  };
}
