# kompis-os/disk-layouts/single-xfs.nix
{ disk, ... }:
{
  disko.devices.disk.${disk.name} = {
    type = "disk";
    device = disk.devices;
    content = {
      type = "gpt";
      partitions = {
        xfs = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "xfs";
            inherit (disk) mountpoint;
            mountOptions = [
              "defaults"
              "noatime"
              "nodiratime"
              "nofail"
            ];
          };
        };
      };
    };
  };
}
