# Playwright MCP plugin configuration
{ lib }:
{
  mkConfig = pkgs: {
    type = "local";
    command = [
      "${pkgs.playwright-mcp}/bin/mcp-server-playwright"
      "--browser=firefox"
      "--headless"
    ];
  };
}
