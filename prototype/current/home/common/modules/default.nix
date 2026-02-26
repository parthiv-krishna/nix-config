# Home optional modules - auto-imported but opt-in enabled
{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;
}
