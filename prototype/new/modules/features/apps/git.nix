# Git feature - home-only
{ lib }:
lib.custom.mkFeature {
  path = [
    "apps"
    "git"
  ];

  homeConfig =
    _cfg:
    _:
    {
      programs.git = {
        enable = true;
        settings.user = {
          name = "Test User";
          email = "test@example.com";
        };
      };
    };
}
