# disk-layouts/raid1-xfs.nix
{
  disk,
  host,
  lib,
  org,
  ...
}:
{

  boot.swraid = {
    enable = true;
    mdadmConf = ''
      MAILADDR postmaster@${org.endpoint}
      MAILFROM ${host.name}@${org.endpoint}
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
      ${disk.name} = {
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
}
