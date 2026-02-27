# Auto-import all manifest files in this directory
{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;
}
