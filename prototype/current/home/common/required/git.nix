# Git configuration - always enabled
_:
{
  programs.git = {
    enable = true;
    settings.user = {
      name = "Test User";
      email = "test@example.com";
    };
  };
}
