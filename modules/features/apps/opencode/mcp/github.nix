{ lib }:
{
  mkConfig = pkgs:
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
