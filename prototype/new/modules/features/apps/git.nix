# Git feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [ "apps" "git" ];

  homeConfig = cfg: { ... }: {
    programs.git = {
      enable = true;
      settings.user = {
        name = "Test User";
        email = "test@example.com";
      };
    };
  };
}
