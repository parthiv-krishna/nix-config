# Minimal hardware config for testing
_:
{
  boot.loader.grub.device = "nodev";
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
}
