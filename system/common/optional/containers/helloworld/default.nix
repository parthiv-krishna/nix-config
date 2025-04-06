{ helpers, ... }:
let
  name = "helloworld";
in
{
  imports = [
    (helpers.mkCompose {
      inherit name;
      src = ./.;
    })
  ];
}
