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
  programs.opencode.settings.mcp.filesystem = {
    type = "local";
    command = [
      "${pkgs.nodejs}/bin/npx"
      "-y"
      "@modelcontextprotocol/server-filesystem"
      "/home"
    ];
    environment.PATH =
      with pkgs;
      lib.makeBinPath [
        bash
        nodejs
      ];
  };
}
