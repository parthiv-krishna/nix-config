# Bash configuration - always enabled
{ ... }:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
    };
  };
}
