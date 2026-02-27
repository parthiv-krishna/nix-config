# MCP plugin configurations for opencode
{ lib }:
let
  filesystem = import ./filesystem.nix { inherit lib; };
  github = import ./github.nix { inherit lib; };
  playwright = import ./playwright.nix { inherit lib; };
in
{
  mkMcpConfig = pkgs: {
    filesystem = filesystem.mkConfig pkgs;
    github = github.mkConfig pkgs;
    playwright = playwright.mkConfig pkgs;
  };
}
