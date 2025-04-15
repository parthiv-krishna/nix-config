# Mounts an array of HDDs with btrfs

{
  devices ? throw "Set this to a list of devices to mount",
  ...
}:

{
  disko.devices = {
    disk = builtins.listToAttrs (
      map (
        device:
        let
          name = builtins.baseNameOf device;
        in
        {
          inherit name;
          value = {
            inherit device;
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                data = {
                  name = "data";
                  size = "100%";
                  content = {
                    type = "filesystem";
                    format = "btrfs";
                    mountpoint = "/hdd/${name}";
                  };
                };
              };
            };
          };
        }
      ) devices
    );
  };
}
