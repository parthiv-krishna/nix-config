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
  programs.opencode.settings.mcp.github =
    let
      githubMcpWrapper = pkgs.writeShellScript "github-mcp-wrapper" ''
        exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-github "$@"
      '';
    in
    {
      type = "local";
      command = [ "${githubMcpWrapper}" ];
      environment.PATH =
        with pkgs;
        lib.makeBinPath [
          bash
          nodejs
        ];
    };
}
