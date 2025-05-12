{ helpers, ... }:
let
  name = "wolweb";
in
{
  imports = [
    (helpers.mkCompose {
      inherit name;
      src = ./.;
    })
  ];

  networking.firewall.allowedTCPPorts = [
    443
  ];
}
