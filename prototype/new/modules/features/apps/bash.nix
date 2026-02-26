# Bash feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "bash" ];

  homeConfig = cfg: { ... }: {
    programs.bash = {
      enable = true;
      shellAliases = {
        ll = "ls -la";
        ".." = "cd ..";
      };
    };
  };
}
