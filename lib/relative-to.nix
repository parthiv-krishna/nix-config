{ lib, ... }:
{
  relativeToRoot = lib.path.append ../.;
  relativeTo = dir: lib.path.append (lib.path.append ../. dir);
}
