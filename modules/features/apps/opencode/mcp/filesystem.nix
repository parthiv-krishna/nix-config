{ lib }:
{
  mkConfig = pkgs: {
    type = "local";
    command = [
      "${pkgs.nodejs}/bin/npx"
      "-y"
      "@modelcontextprotocol/server-filesystem"
      "/home"
    ];
    environment.PATH =
      with pkgs;
      lib.makeBinPath [
        bash
        nodejs
      ];
  };
}
