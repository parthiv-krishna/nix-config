{
  lib,
  inputs,
  stdenv,
}:
inputs.zeroclaw.packages.${stdenv.hostPlatform.system}.zeroclaw.overrideAttrs (old: {
  env = (old.env or { }) // {
    CARGO_PROFILE_RELEASE_LTO = "thin";
  };
  patches = (old.patches or [ ]) ++ [
    (lib.custom.relativeToRoot "patches/zeroclaw/signal-group-routing.patch")
    (lib.custom.relativeToRoot "patches/zeroclaw/silent-replies.patch")
  ];
  cargoBuildFlags = old.cargoBuildFlags ++ [
    "--features"
    "channel-signal"
  ];
})
