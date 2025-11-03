{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.postgresql;
  eachDatabase = lib.filterAttrs (db: dbCfg: dbCfg.enable) cfg.databases;
in
{
  options.kompis-os.postgresql = {
    enable = lib.mkEnableOption "postgresql";
    databases = lib.mkOption {
      description = "databases to manage";
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, config, ... }:
          {
            options = {
              enable = lib.mkEnableOption "database";
              name = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              user = lib.mkOption {
                type = lib.types.str;
                default = config.name;
              };
              dumpPath = lib.mkOption {
                type = lib.types.str;
                default = "/var/lib/${config.name}/dbdump.sql";
              };
            };
          }
        )
      );
    };
  };

  config = lib.mkIf (cfg.databases != { }) {
    kompis-os.preserve.databases = [
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
      }
    ];

    services.postgresql = {
      enable = true;
      package = pkgs.postgresql_17;
      extensions =
        ps: with ps; [
          postgis
          pg_repack
        ];
    };

    systemd.services = lib.mapAttrs' (
      db: dbCfg:
      lib.nameValuePair "${dbCfg.name}-pgsql-dump" {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.postgresql}/bin/pg_dump ${dbCfg.name} > ${dbCfg.dumpPath}'";
          User = dbCfg.user;
          Group = dbCfg.user;
        };
      }
    ) eachDatabase;
  };
}
