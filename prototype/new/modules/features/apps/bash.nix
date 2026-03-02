# Bash feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "bash"
  ];

  homeConfig =
    _cfg:
    _:
    {
      programs.bash = {
        enable = true;
        shellAliases = {
          ll = "ls -la";
          ".." = "cd ..";
        };
      };
    };
}
