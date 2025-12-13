{
  config,
  lib,
  ...
}:
let
  cfg = config.custom.ai-tools;
in
{
  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      enable = true;

      mcpServers = cfg.mcp-servers;

      settings = {
        includeCoAuthoredBy = false;
        theme = "dark";
        permissions = {
          defaultMode = "acceptEdits";
          allow = [
            "Edit"
            "MultiEdit"
            "Write"
            "Read"
            "Bash(git diff:*)"
            "Bash(git status:*)"
            "Bash(git log:*)"
            "Bash(nix build:*)"
            "Bash(nix flake:*)"
          ];
          ask = [
            "Bash(git push:*)"
            "Bash(git commit:*)"
            "Bash(rm:*)"
          ];
          deny = [
            "Read(./.env)"
            "Read(./secrets/**)"
            "Read(./**/secret*)"
            "Bash(curl:*)"
            "Bash(wget:*)"
          ];
        };
      };
    };

    unfree.allowedPackages = [
      "claude-code"
    ];

    custom.persistence.directories = [
      ".claude"
    ];
  };
}
