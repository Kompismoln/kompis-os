{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.fastapi;

  eachSite = lib.filterAttrs (_: cfg: cfg.enable) cfg.sites;
  stateDir = hostname: "/var/lib/${hostname}/fastapi";
  envToList = env: lib.mapAttrsToList (name: value: "${name}=${toString value}") env;

  siteOpts = {
    options = {
      enable = lib.mkEnableOption "FastAPI app";
      port = lib.mkOption {
        description = "Listening port.";
        example = 8000;
        type = lib.types.port;
      };
      ssl = lib.mkOption {
        description = "Whether to enable SSL (https) support.";
        type = lib.types.bool;
      };
      appname = lib.mkOption {
        description = "Internal namespace";
        type = lib.types.str;
        default = null;
      };
      hostname = lib.mkOption {
        description = "Network namespace";
        type = lib.types.str;
        default = null;
      };
    };
  };

  fastapiPkgs = appname: inputs.${appname}.packages.${host.system}.fastapi;

  envs = lib.mapAttrs (_: cfg: {
    ALLOW_ORIGINS = "'[\"${if cfg.ssl then "https" else "http"}://${cfg.hostname}\"]'";
    DB_DSN = "postgresql+psycopg2://${cfg.appname}@:5432/${cfg.appname}";
    ENV = "production";
    HOSTNAME = cfg.hostname;
    LOG_LEVEL = "error";
    SECRETS_DIR = dirOf config.sops.secrets."${cfg.appname}/secret_key".path;
    SSL = if cfg.ssl then "true" else "false";
    STATE_DIR = stateDir cfg.appname;
    ALEMBIC_CONFIG = "${(fastapiPkgs cfg.appname).alembic}/alembic.ini";
  }) eachSite;

  bins = lib.mapAttrs (
    _: cfg:
    ((fastapiPkgs cfg.appname).bin.overrideAttrs {
      env = envs.${cfg.appname};
      name = "${cfg.appname}-manage";
    })
  ) eachSite;
in
{

  options.kompis-os.fastapi = {
    sites = lib.mkOption {
      type = with lib.types; attrsOf (submodule siteOpts);
      default = { };
      description = "Definition of per-domain FastAPI apps to serve.";
    };
  };

  config = lib.mkIf (eachSite != { }) {

    environment.systemPackages = lib.mapAttrsToList (_: bin: bin) bins;

    sops.secrets = lib.concatMapAttrs (_: cfg: {
      "${cfg.appname}/secret_key" = {
        owner = cfg.appname;
        group = cfg.appname;
      };
    }) eachSite;

    systemd.tmpfiles.rules = lib.flatten (
      lib.mapAttrsToList (_: cfg: [
        "d '${stateDir cfg.appname}' 0750 ${cfg.appname} ${cfg.appname} - -"
        "Z '${stateDir cfg.appname}' 0750 ${cfg.appname} ${cfg.appname} - -"
      ]) eachSite
    );

    services.nginx.virtualHosts = lib.mapAttrs (_: cfg: {
      serverName = cfg.hostname;
      forceSSL = cfg.ssl;
      enableACME = cfg.ssl;
      locations."/api" = {
        recommendedProxySettings = true;
        proxyPass = "http://localhost:${toString cfg.port}";
      };
    }) eachSite;

    systemd.services = lib.concatMapAttrs (_: cfg: {
      "${cfg.appname}-fastapi" = {
        description = "serve ${cfg.appname}-fastapi";
        serviceConfig = {
          ExecStart = "${(fastapiPkgs cfg.appname).app}/bin/uvicorn app.main:fastapi --host localhost --port ${toString cfg.port}";
          User = cfg.appname;
          Group = cfg.appname;
          Environment = envToList envs.${cfg.appname};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${cfg.appname}-fastapi-migrate" = {
        path = [ pkgs.bash ];
        description = "migrate ${cfg.appname}-fastapi";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${bins.${cfg.appname}}/bin/${cfg.appname}-manage migrate";
          User = cfg.appname;
          Group = cfg.appname;
          Environment = envToList envs.${cfg.appname};
        };
      };

      "${cfg.appname}-pgsql-dump" = {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.postgresql}/bin/pg_dump -U ${cfg.appname} ${cfg.appname} > ${stateDir cfg.appname}/dbdump.sql'";
          User = cfg.appname;
          Group = cfg.appname;
        };
      };
      "${cfg.appname}-pgsql-restore" = {
        description = "restore postgresql database from snapshot";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.postgresql}/bin/psql -U ${cfg.appname} ${cfg.appname} < ${stateDir cfg.appname}/dbdump.sql'";
          User = cfg.appname;
          Group = cfg.appname;
        };
      };
    }) eachSite;

    systemd.timers = lib.concatMapAttrs (_: cfg: {
      "${cfg.appname}-pgsql-dump" = {
        description = "Scheduled PostgreSQL database dump";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "${cfg.appname}-pgsql-dump.service";
        };
      };
    }) eachSite;

    #system.activationScripts = mapAttrs (name: cfg: {
    #  text = ''
    #    ${pkgs.systemd}/bin/systemctl start ${cfg.appname}-fastapi-migrate
    #  '';
    #}) eachSite;
  };
}
