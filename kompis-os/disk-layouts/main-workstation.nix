# kompis-os/disk-layouts/main-workstation.nix
{
  self,
  ...
}:
let
  name = "main-workstation";
in
{
  flake.nixosModules."disk-layout-${name}" =
    {
      config,
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
        boot.initrd.secrets."/${cfg.luksKeyFile}" = config.sops.secrets.luks-key.path;

        kompis-os = {
          locksmith.luksDevice = "/dev/disk/by-partlabel/${cfg.luksPartitionLabel}";
          preserve.enable = true;
        };

        disko.devices = (self.diskoModules.${name} name cfg).disko.devices;
      };

    };

  flake.diskoModules.${name} = disk: diskCfg: {
    disko.devices = {
      nodev = {
        "/tmp" = {
          fsType = "tmpfs";
          mountOptions = [
            "size=1G"
            "defaults"
            "noatime"
            "nosuid"
            "nodev"
            "noexec"
            "mode=1777"
          ];
        };
      };
      disk = {
        main = {
          type = "disk";
          device = diskCfg.device;
          content = {
            type = "gpt";
            partitions = {
              boot = {
                size = "1M";
                type = "EF02";
                priority = 1;
              };
              ESP = {
                size = "1G";
                type = "EF00";
                content = {
                  type = "filesystem";
                  format = "vfat";
                  mountpoint = "/boot";
                  mountOptions = [ "umask=0077" ];
                };
              };
              luks = {
                size = "100%";
                label = diskCfg.luksPartitionLabel;
                content = {
                  type = "luks";
                  name = "cryptroot";
                  settings = {
                    keyFile = diskCfg.luksKeyFile;
                    allowDiscards = true;
                  };
                  content = {
                    type = "lvm_pv";
                    vg = "pool";
                  };
                };
              };
            };
          };
        };
      };
      lvm_vg = {
        pool = {
          type = "lvm_vg";
          lvs = {
            root = {
              size = "1G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "nodiratime"
                ];
              };
            };
            var = {
              size = "1G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/var";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "nodiratime"
                ];
              };
            };
            keys = {
              size = "1G";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/keys";
                mountOptions = [
                  "defaults"
                  "noatime"
                  "nodiratime"
                  "noexec"
                  "nosuid"
                  "nodev"
                ];
              };
            };
            swap = {
              size = "12G";
              content = {
                type = "swap";
              };
            };
            state = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                mountpoint = "/mnt/state";
                mountOptions = [
                  "subvolid=5"
                  "noatime"
                  "space_cache=v2"
                ];
                subvolumes = {
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                    ];
                  };
                  "@storage" = {
                    mountpoint = "/srv/storage";
                    mountOptions = [
                      "compress=zstd"
                      "noatime"
                      "space_cache=v2"
                    ];
                  };
                  "@backup" = {
                    mountpoint = "/srv/backup";
                    mountOptions = [
                      "compress=no"
                      "noatime"
                      "space_cache=v2"
                      "ro"
                    ];
                  };
                  "@snapshots" = {
                    mountpoint = "/mnt/snapshots";
                    mountOptions = [
                      "compress=no"
                      "noatime"
                      "space_cache=v2"
                    ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
