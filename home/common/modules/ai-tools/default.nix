{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ai-tools;
  githubTokenSecret = "ai-tools/github-token";
in
{
  imports = lib.custom.scanPaths ./.;

  options.custom.ai-tools = {
    enable = lib.mkEnableOption "AI tools package set";

    mcp-servers = lib.mkOption {
      type = lib.types.attrsOf lib.types.attrs;
      default = { };
      description = "MCP servers configuration shared across AI tools";
    };

    github-token-path = lib.mkOption {
      type = lib.types.str;
      default = config.sops.secrets.${githubTokenSecret}.path;
      description = "Path to file containing GitHub token for MCP authentication";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.${githubTokenSecret} = { };

    custom.ai-tools.mcp-servers = {
      filesystem = {
        type = "stdio";
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@modelcontextprotocol/server-filesystem"
          "/home"
        ];
      };

      playwright = {
        type = "stdio";
        command = "${pkgs.nodejs}/bin/npx";
        args = [
          "-y"
          "@playwright/mcp@latest"
        ];
      };
    };
  };
}
