{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.opencode;
in
lib.mkIf cfg.enable {
  programs.opencode.settings.mcp.playwright = {
    type = "local";
    command = [
      "${pkgs.playwright-mcp}/bin/mcp-server-playwright"
      "--browser=firefox"
      "--headless"
    ];
  };
}
