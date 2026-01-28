# kompis-os/nixos/preserve.nix
{
  config,
  inputs,
  lib,
  options,
  ...
}:

let
  cfg = config.kompis-os.preserve;

  # Piggyback on preservation's options for files and directories
  preserveAtOptions = options.preservation.preserveAt.type.nestedTypes.elemType.getSubOptions [ ];
in
{
  imports = [
    inputs.preservation.nixosModules.preservation
  ];

  options.kompis-os.preserve = rec {
    inherit (preserveAtOptions) files directories;
    databases = directories;
    enable = lib.mkEnableOption ''ephemeral root on this host'';
    storage = lib.mkOption {
      description = "permanent storage";
      type = lib.types.str;
      default = "/srv/storage";
    };
    database = lib.mkOption {
      description = "permanent no-cow storage";
      type = lib.types.str;
      default = "/srv/database";
    };
  };

  config = lib.mkIf cfg.enable {

    preservation = {
      enable = true;
      preserveAt.${cfg.storage} = {
        directories = [
          "/var/lib/nixos"
          "/var/lib/systemd"
        ]
        ++ cfg.directories;
        files = [
          {
            file = "/etc/machine-id";
            inInitrd = true;
          }
        ]
        ++ cfg.files;
      };
      preserveAt.${cfg.database} = {
        directories = cfg.databases;
      };
    };

    security.sudo = {
      extraConfig = ''
        Defaults lecture = never
      '';
    };

    fileSystems."/keys".neededForBoot = true;

    systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

    boot.initrd.systemd.enable = true;

    services.journald.extraConfig = ''
      SystemMaxUse=100M
      SystemKeepFree=200M
      MaxRetentionSec=1week
    '';
  };
}
