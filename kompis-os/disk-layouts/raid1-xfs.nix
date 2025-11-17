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
    {
      host,
      ...
    }@args:

    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      inherit (self.diskoModules.${name} args) disko;

      environment.systemPackages = [
        inputs.disko.packages.default
      ];

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

  flake.diskoModules.${name} =
    { host, ... }:
    {
      disko.devices = {
        disk = lib.mapAttrs (disk: diskCfg: {
          type = "disk";
          device = diskCfg.device;
          content = {
            type = "gpt";
            partitions = {
              raid = {
                size = "100%";
                content = {
                  type = "mdraid";
                  name = "raid1";
                };
              };
            };
          };
        }) host.disk-layouts.${name};
        mdadm = {
          raid1 = {
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
                    mountpoint = host;
                  };
                };
              };
            };
          };
        };
      };
    };

}
