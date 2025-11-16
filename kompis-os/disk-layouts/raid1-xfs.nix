# kompis-os/roles/raid1-xfs.nix
{
  inputs,
  lib,
  self,
  ...
}:
{
  flake.diskoConfigurations.raid1-xfs =
    { host, ... }:
    let
      hostCfg = inputs.org.host.${host};
    in
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
        }) hostCfg.raid1-xfs;
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
                    mountpoint = "/mnt/raid1";
                  };
                };
              };
            };
          };
        };
      };
    };

  flake.nixosModules.raid1-xfs =
    {
      host,
      ...
    }:

    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko = (self.diskoConfigurations.raid1-xfs host).disko;

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
}
