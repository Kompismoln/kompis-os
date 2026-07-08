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
              MAILADDR postmaster@${inputs.org.endpoint}
              MAILFROM ${host.name}@${inputs.org.endpoint}
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

  flake.diskoModules.${name} = disk: {
    disko.devices = {
      disk = lib.listToAttrs (
        lib.imap0 (
          i: device:
          lib.nameValuePair "${disk.name}-${toString i}" {
            inherit device;
            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                raid = {
                  size = "100%";
                  content = {
                    type = "mdraid";
                    inherit (disk) name;
                  };
                };
              };
            };
          }
        ) disk.devices
      );
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
                  inherit (disk) mountpoint;
                };
              };
            };
          };
        };
      };
    };
  };
}
