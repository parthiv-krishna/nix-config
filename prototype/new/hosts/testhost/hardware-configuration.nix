# Minimal hardware config for testing
{ ... }:
{
  boot.loader.grub.device = "nodev";
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
  };
}
