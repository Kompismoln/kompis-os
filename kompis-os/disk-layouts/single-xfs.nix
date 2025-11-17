# kompis-os/disk-layouts/single-xfs.nix
{
  inputs,
  self,
  ...
}:
let
  name = "single-xfs";
in
{
  flake.nixosModules."disk-layout-${name}" = args: {
    imports = [
      inputs.disko.nixosModules.disko
    ];

    inherit (self.diskoModules.${name} args) disko;
  };

  flake.diskoModules.${name} =
    { host, ... }:
    {
      disko.devices = {
        disk.${name} = {
          type = "disk";
          device = host.disk-layouts.${name}.device;
          content = {
            type = "gpt";
            partitions = {
              xfs = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "xfs";
                  mountpoint = host.disk-layouts.${name}.mountpoint;
                  mountOptions = [
                    "defaults"
                    "noatime"
                    "nodiratime"
                  ];
                };
              };
            };
          };
        };
      };
    };
}
