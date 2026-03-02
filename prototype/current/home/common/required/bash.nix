# Bash configuration - always enabled
_:
{
  programs.bash = {
    enable = true;
    shellAliases = {
      ll = "ls -la";
      ".." = "cd ..";
    };
  };
}
