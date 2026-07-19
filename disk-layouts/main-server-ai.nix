# disk-layouts/main-server-ai.nix
{ host, disk, ... }:
{
  boot = {
    zfs.devNodes = "/dev/disk/by-uuid";
    zfs.forceImportRoot = false;
  };
  o11n = {
    preserve.enable = true;
  };

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
      device = disk.devices;
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
            label = "disk-main-luks";
            content = {
              type = "luks";
              name = "cryptswap";
              extraFormatArgs = [ "--pbkdf pbkdf2" ];
              settings = {
                keyFile = host.luksKeyFile;
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
              keylocation = "file://${host.luksKeyFile}";
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
              keylocation = "file://${host.luksKeyFile}";
            };
          };
          "srv/storage" = {
            type = "zfs_fs";
            mountpoint = "/srv/storage";
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${host.luksKeyFile}";
              compression = "zstd";
            };
          };
          "srv/database" = {
            type = "zfs_fs";
            mountpoint = "/srv/database";
            options = {
              encryption = "aes-256-gcm";
              keyformat = "passphrase";
              keylocation = "file://${host.luksKeyFile}";
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
}
