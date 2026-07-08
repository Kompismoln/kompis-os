# kompis-os/disk-layouts/main-server-ai.nix
{
  self,
  ...
}:
let
  name = "main-server-ai";
in
{
  flake.nixosModules."disk-layout-${name}" =
    {
      host,
      lib,
      ...
    }:
    let
      disks = builtins.filter (disk: disk.module == name) (lib.attrValues host.disk);
    in
    {
      config = {
        boot = {
          zfs.devNodes = "/dev/disk/by-uuid";
          zfs.forceImportRoot = false;
        };
        kompis-os = {
          preserve.enable = true;
        };

        networking.hostId = host.machine-id;
        disko = lib.mkMerge (map (disk: (self.diskoModules.${name} disk).disko) disks);
      };
    };

  flake.diskoModules.${name} = disk: {
    disko.devices = {
      nodev = {
        "/" = {
          fsType = "tmpfs";
          mountOptions = [
            "size=1G"
            "mode=755"
          ];
        };
      };
      disk.main = {
        type = "disk";
        inherit (disk) devices;
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              size = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            luks = {
              size = "64G";
              content = {
                type = "luks";
                name = "cryptswap";
                extraFormatArgs = [ "--pbkdf pbkdf2" ];
                settings = {
                  keyFile = disk.luksKeyFile;
                  allowDiscards = true;
                };
                content = {
                  type = "swap";
                };
              };
            };
            zfs = {
              size = "100%";
              content = {
                type = "zfs";
                pool = "zroot";
              };
            };
          };
        };
      };
      zpool = {
        zroot = {
          type = "zpool";
          options = {
            ashift = "12";
            autotrim = "on";
          };
          rootFsOptions = {
            acltype = "posixacl";
            canmount = "off";
            dnodesize = "auto";
            normalization = "formD";
            relatime = "on";
            xattr = "sa";
            mountpoint = "none";
          };
          datasets = {
            "system/var" = {
              type = "zfs_fs";
              mountpoint = "/var";
              options = {
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${disk.luksKeyFile}";
                quota = "1G";
                compression = "zstd";
              };
            };
            "system/nix" = {
              type = "zfs_fs";
              mountpoint = "/nix";
              options = {
                compression = "zstd";
                atime = "off";
              };
            };
            "system/keys" = {
              type = "zfs_fs";
              mountpoint = "/keys";
              options = {
                recordsize = "4k";
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${disk.luksKeyFile}";
              };
            };
            "srv/storage" = {
              type = "zfs_fs";
              mountpoint = "/srv/storage";
              options = {
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${disk.luksKeyFile}";
                compression = "zstd";
              };
            };
            "srv/database" = {
              type = "zfs_fs";
              mountpoint = "/srv/database";
              options = {
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${disk.luksKeyFile}";
                recordsize = "16k";
                logbias = "throughput";
                primarycache = "metadata";
              };
            };
            "srv/models" = {
              type = "zfs_fs";
              mountpoint = "/srv/models";
              options = {
                compression = "off";
                recordsize = "1M";
                atime = "off";
              };
            };
          };
        };
      };
    };
  };
}
