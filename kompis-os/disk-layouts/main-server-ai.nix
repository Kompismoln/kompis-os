# kompis-os/disk-layouts/main-server-ai.nix
{
  inputs,
  self,
  ...
}:
let
  name = "main-server-ai";
in
{
  flake.nixosModules."disk-layout-${name}" =
    {
      config,
      host,
      lib,
      ...
    }:
    let
      cfg = config.kompis-os.disk-layouts.${name}.main;
    in
    {
      options.kompis-os.disk-layouts.${name}.main = {
        device = lib.mkOption {
          type = lib.types.str;
        };
        luksKeyFile = lib.mkOption {
          type = lib.types.str;
          default = "/luks-key";
        };
        luksPartitionLabel = lib.mkOption {
          type = lib.types.str;
          default = "disk-main-luks";
        };
      };

      config = {
        sops.secrets.luks-key = { };
        boot.initrd.secrets."${cfg.luksKeyFile}" = config.sops.secrets.luks-key.path;
        kompis-os = {
          locksmith.luksDevice = "/dev/disk/by-partlabel/${cfg.luksPartitionLabel}";
          preserve.enable = true;
        };
        boot.zfs.devNodes = "/dev/disk/by-uuid";

        networking.hostId = lib.strings.fixedWidthString 8 "0" (toString inputs.org.host.${host.name}.id);
        disko.devices = (self.diskoModules.${name} name cfg).disko.devices;
      };
    };

  flake.diskoModules.${name} = disk: diskCfg: {
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
        device = diskCfg.device;
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
                  keyFile = diskCfg.luksKeyFile;
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
                keylocation = "file://${diskCfg.luksKeyFile}";
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
                keylocation = "file://${diskCfg.luksKeyFile}";
              };
            };
            "srv/storage" = {
              type = "zfs_fs";
              mountpoint = "/srv/storage";
              options = {
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${diskCfg.luksKeyFile}";
                compression = "zstd";
              };
            };
            "srv/database" = {
              type = "zfs_fs";
              mountpoint = "/srv/database";
              options = {
                encryption = "aes-256-gcm";
                keyformat = "passphrase";
                keylocation = "file://${diskCfg.luksKeyFile}";
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
