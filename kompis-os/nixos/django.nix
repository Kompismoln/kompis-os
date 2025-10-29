{
  config,
  host,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.django;

  eachApp = lib.filterAttrs (name: appCfg: appCfg.enable) cfg.apps;

  stateDir = app: "/var/lib/${app}/django";

  appOpts = lib'.mkAppOpts host "django" {
    options = {
      appname = lib.mkOption {
        description = "django app name";
        type = lib.types.str;
        default = "app";
      };
      locationStatic = lib.mkOption {
        description = "Location pattern for static files, empty string -> no static";
        type = lib.types.str;
        default = "/static/";
      };
      locationProxy = lib.mkOption {
        description = "Location pattern for proxy to django, empty string -> no proxy";
        type = lib.types.str;
        example = "~ ^/(api|admin)";
        default = "/";
      };
      celery = {
        enable = lib.mkEnableOption "celery et al";
        port = lib.mkOption {
          description = "Listening port for message broker.";
          type = with lib.types; nullOr port;
          default = null;
        };
      };
    };
  };

  envs = lib.mapAttrs (
    app: appCfg:
    {
      DB_NAME = app;
      DB_USER = app;
      DB_HOST = "/run/postgresql";
      DEBUG = "false";
      DJANGO_SETTINGS_MODULE = "${appCfg.appname}.settings";
      HOST = appCfg.endpoint;
      LOG_LEVEL = "WARNING";
      SCHEME = if appCfg.ssl then "https" else "http";
      SECRET_KEY_FILE = config.sops.secrets."${appCfg.entity}/secret-key".path;
      STATE_DIR = stateDir app;
    }
    // (lib.optionalAttrs appCfg.celery.enable {
      CELERY_BROKER_URL = "redis://127.0.0.1:${toString (appCfg.celery.port)}/0";
      FLOWER_URL_PREFIX = "/flower";
    })
  ) eachApp;

  mkDjangoManage =
    app: appCfg:
    pkgs.writeShellApplication {
      name = "${app}-manage";
      text = ''
        exec ${appCfg.package.django-manage}/bin/manage "$@"
      '';
      runtimeEnv = envs.${app};
    };

  bins = lib.mapAttrs mkDjangoManage eachApp;
in
{

  options.kompis-os.django = {
    apps = lib.mkOption {
      type = with lib.types; attrsOf (submodule appOpts);
      default = { };
      description = "Definition of per-domain Django apps to serve.";
    };
  };

  config = lib.mkIf (eachApp != { }) {

    environment.systemPackages = lib.mapAttrsToList (_: bin: bin) bins;

    kompis-os.preserve.directories = lib.mapAttrsToList (app: appCfg: {
      directory = stateDir app;
      how = "symlink";
      user = app;
      group = app;
    }) eachApp;

    sops.secrets = lib.mapAttrs' (
      app: appCfg:
      lib.nameValuePair "${appCfg.entity}/secret-key" {
        sopsFile = lib'.secrets "app" appCfg.entity;
        owner = app;
        group = app;
      }
    ) eachApp;

    kompis-os.users = lib.mapAttrs (app: appCfg: {
      class = "app";
      publicKey = false;
    }) eachApp;

    services.nginx.virtualHosts = lib.mapAttrs' (
      app: appCfg:
      lib.nameValuePair appCfg.endpoint {
        forceSSL = appCfg.ssl;
        enableACME = appCfg.ssl;
        locations =
          lib.optionalAttrs (appCfg.locationProxy != "") {
            ${appCfg.locationProxy} = {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:${toString (lib'.ports app)}";
            };
          }
          // lib.optionalAttrs (appCfg.locationStatic != "") {
            ${appCfg.locationStatic} = {
              alias = "${appCfg.package.django-static}/";
            };
          }
          // lib.optionalAttrs (appCfg.celery.enable) {
            "/auth" = {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:${toString (lib'.ports app)}";
            };
            "/flower/" = {
              proxyPass = "http://localhost:5555";
              extraConfig = ''
                auth_request /auth/;
              '';
            };
          };
      }
    ) eachApp;

    systemd.services = lib'.mergeAttrs (app: appCfg: {
      "${app}" = {
        description = "serve ${app}";
        serviceConfig = {
          ExecStart = "${appCfg.package.django-app}/bin/gunicorn ${appCfg.appname}.wsgi:application --bind localhost:${toString (lib'.ports app)}";
          User = app;
          Group = app;
          Environment = lib'.envToList envs.${app};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${app}-celery" = lib.mkIf appCfg.celery.enable {
        description = "start ${app}-celery";
        serviceConfig = {
          ExecStart = "${appCfg.package.django-app}/bin/celery -A ${appCfg.appname} worker -l warning";
          User = app;
          Group = app;
          Environment = lib'.envToList envs.${app};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${app}-flower" = lib.mkIf appCfg.celery.enable {
        description = "start ${app}-flower";
        serviceConfig = {
          ExecStart = "${appCfg.package.django-app}/bin/celery -A ${appCfg.appname} flower --port=5555";
          User = app;
          Group = app;
          Environment = lib'.envToList envs.${app};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${app}-migrate" = {
        description = "migrate ${app}";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${appCfg.package.django-app}/bin/django-admin migrate";
          User = app;
          Group = app;
          Environment = lib'.envToList envs.${app};
        };
      };
      "${app}-pgsql-dump" = {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-dump}/bin/pgsql-dump ${app} ${stateDir app}";
          User = app;
          Group = app;
        };
      };
      "${app}-pgsql-init" = {
        description = "create database/user-pair";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-init}/bin/pgsql-init ${app}";
          User = "postgres";
          Group = "postgres";
        };
      };
      "${app}-pgsql-restore" = {
        description = "restore postgresql database from snapshot";
        after = [ "${app}-pgsql-init.service" ];
        requires = [ "${app}-pgsql-init.service" ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-restore}/bin/pgsql-restore ${app} ${stateDir app}";
          User = app;
          Group = app;
        };
      };
    }) eachApp;

    systemd.timers = lib'.mergeAttrs (app: appCfg: {
      "${app}-pgsql-dump" = {
        description = "Scheduled PostgreSQL database dump";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "${app}-pgsql-dump.service";
        };
      };
    }) eachApp;
  };
}
