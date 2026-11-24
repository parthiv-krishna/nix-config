{ lib }:
lib.custom.mkFeature {
  path = [
    "meta"
    "root"
  ];

  systemConfig = _cfg: _: {
    users.users.root.hashedPassword = "!";
  };
}
