{
  stdenvNoCC,
  fetchFromGitHub,
  python3,
  makeWrapper,
  lib,
}:
let
  python = python3.withPackages (ps: [
    ps.mcp
    ps.httpx
    ps.python-dotenv
    ps.rich
  ]);
in
stdenvNoCC.mkDerivation {
  pname = "jellyseerr-mcp";
  version = "unstable-6d45ed4";
  src = fetchFromGitHub {
    owner = "aserper";
    repo = "jellyseerr-mcp";
    rev = "6d45ed4a28ba7f307ccf52b0e868783b46aa97c2";
    hash = "sha256-AHnpKeK33yDALRTUTE3Jd2U54GfpPkb4M+39Y9ggAh0=";
  };
  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;
  installPhase = ''
    runHook preInstall
    mkdir -p "$out/lib" "$out/bin"
    cp -r jellyseerr_mcp "$out/lib/"
    makeWrapper ${python}/bin/python3 "$out/bin/jellyseerr-mcp" \
      --set PYTHONPATH "$out/lib" \
      --add-flags "-m jellyseerr_mcp"
    runHook postInstall
  '';
  meta = {
    description = "Jellyseerr search, request, and status MCP server";
    homepage = "https://github.com/aserper/jellyseerr-mcp";
    license = lib.licenses.mit;
    mainProgram = "jellyseerr-mcp";
  };
}
