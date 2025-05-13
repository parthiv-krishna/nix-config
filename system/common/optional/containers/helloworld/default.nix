{
  lib,
  ...
}:
let
  name = "helloworld";
in
{
  imports = [
    (lib.custom.mkCompose {
      inherit name;
      src = ./.;
    })
  ];
}
