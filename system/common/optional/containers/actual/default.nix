{
  lib,
  ...
}:
let
  name = "actual";
in
{
  imports = [
    (lib.custom.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  # persist app data
  environment.persistence."/persist/system" = {
    directories = [
      "/var/lib/actual"
    ];
  };
}
