# System required modules - always imported
{ lib, inputs, ... }:
{
  imports = lib.custom.scanPaths ./.;
}
