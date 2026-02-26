# Git configuration - always enabled
{ ... }:
{
  programs.git = {
    enable = true;
    settings.user = {
      name = "Test User";
      email = "test@example.com";
    };
  };
}
