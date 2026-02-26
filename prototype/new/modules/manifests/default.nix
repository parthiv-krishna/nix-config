# Manifests - auto-import all manifest modules
{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;
}
