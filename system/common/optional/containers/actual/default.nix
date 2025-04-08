{ helpers, ... }:
let
  name = "actual";
in
{
  imports = [
    (helpers.mkCompose {
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
