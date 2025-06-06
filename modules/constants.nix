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
      glances = mkPortConstant 61208;
      homepage = mkPortConstant 8082;
      immich = mkPortConstant 2283;
      jellyfin = mkPortConstant 8096;
      ollama = mkPortConstant 11434;
      prometheus = mkPortConstant 9092;
      prometheus-crowdsec = mkPortConstant 9200;
      prometheus-node = mkPortConstant 9201;
      prometheus-nut = mkPortConstant 9202;
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
