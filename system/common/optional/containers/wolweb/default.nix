{
  lib,
  ...
}:
let
  name = "wolweb";
in
{
  imports = [
    (lib.custom.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  networking.firewall.allowedTCPPorts = [
    443
  ];
}
