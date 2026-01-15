{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ai-tools;
in
{
  imports = lib.custom.scanPaths ./.;

  options.custom.ai-tools = {
    enable = lib.mkEnableOption "AI tools package set";

    mcpServers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      description = "MCP servers configuration shared across AI tools";

      # configured below, can be appended to in other places
      default = { };
    };
  };

  config = lib.mkIf cfg.enable {

    custom.ai-tools.mcpServers = {
      filesystem = {
        type = "stdio";
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/home"
        ];
        env.PATH =
          with pkgs;
          lib.makeBinPath [
            bash
            nodejs
          ];
      };

      github =
        let
          githubMcpWrapper = pkgs.writeShellScript "github-mcp-wrapper" ''
            exec ${pkgs.nodejs}/bin/npx -y @modelcontextprotocol/server-github "$@"
          '';
        in
        {
          type = "stdio";
          command = "${githubMcpWrapper}";
          env.PATH =
            with pkgs;
            lib.makeBinPath [
              bash
              nodejs
            ];
        };

      playwright = {
        type = "stdio";
        command = "${pkgs.playwright-mcp}/bin/mcp-server-playwright";
        args = [
          "--browser=firefox"
          "--headless"
        ];
      };
    };
  };
}
