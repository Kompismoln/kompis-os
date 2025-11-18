# kompis-os/disk-layouts/single-xfs.nix
{
  inputs,
  lib,
  self,
  ...
}:
let
  name = "single-xfs";
in
{
  flake.nixosModules."disk-layout-${name}" =
    { config, ... }:
    let
      cfg = config.kompis-os.disk-layouts.${name};
    in
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      options.kompis-os.disk-layouts.${name} = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              device = lib.mkOption {
                type = lib.types.str;
              };
              mountpoint = lib.mkOption {
                type = lib.types.str;
              };
            };
          }
        );
      };

      config = {
        disko.devices.disk = lib.mapAttrs (
          disk: diskCfg: (self.diskoModules.${name} disk diskCfg).disko.devices.disk.${disk}
        ) cfg;
      };
    };

  flake.diskoModules.${name} = disk: diskCfg: {
    disko.devices.disk.${disk} = {
      type = "disk";
      device = diskCfg.device;
      content = {
        type = "gpt";
        partitions = {
          xfs = {
            size = "100%";
            content = {
              type = "filesystem";
              format = "xfs";
              mountpoint = diskCfg.mountpoint;
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
}
