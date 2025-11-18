# kompis-os/disk-layouts/raid1-xfs.nix
{
  inputs,
  lib,
  self,
  ...
}:
let
  name = "raid1-xfs";
in
{
  flake.nixosModules."disk-layout-${name}" =
    { config, host, ... }:
    {
      options.kompis-os.disk-layouts.${name} = lib.mkOption {
        default = { };
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              mountpoint = lib.mkOption {
                default = null;
                type = lib.types.nullOr lib.types.str;
              };
              disks = lib.mkOption {
                type = lib.types.attrsOf (
                  lib.types.submodule {
                    options = {
                      device = lib.mkOption {
                        type = lib.types.str;
                      };
                    };
                  }
                );
              };
            };
          }
        );
      };
      config =
        let
          cfg = config.kompis-os.disk-layouts.${name};
        in
        lib.mkIf (cfg != { }) {

          disko = lib.mkMerge (
            lib.mapAttrsToList (disk: diskCfg: (self.diskoModules.${name} disk diskCfg).disko) cfg
          );

          boot.swraid = {
            enable = true;
            mdadmConf = ''
              MAILADDR postmaster@${inputs.org.domain}
              MAILFROM mdadm@${host.name}
            '';
          };

          systemd.services.mdmonitor = {
            enable = true;
            wantedBy = [ "multi-user.target" ];
          };

          services.smartd = {
            enable = true;
            notifications = {
              mail.enable = true;
              wall.enable = true;
            };
          };
        };
    };

  flake.diskoModules.${name} = disk: diskCfg: {
    disko.devices = {
      disk = lib.mapAttrs' (
        rDisk: rDiskCfg:
        lib.nameValuePair "${disk}-${rDisk}" {
          type = "disk";
          device = rDiskCfg.device;
          content = {
            type = "gpt";
            partitions = {
              raid = {
                size = "100%";
                content = {
                  type = "mdraid";
                  name = disk;
                };
              };
            };
          };
        }
      ) diskCfg.disks;
      mdadm = {
        ${disk} = {
          type = "mdadm";
          level = 1;
          content = {
            type = "gpt";
            partitions = {
              primary = {
                size = "100%";
                content = {
                  type = "filesystem";
                  format = "xfs";
                  mountpoint = diskCfg.mountpoint or null;
                };
              };
            };
          };
        };
      };
    };
  };
}
