# Home required modules - always imported
{ lib, ... }:
{
  imports = lib.custom.scanPaths ./.;
}
