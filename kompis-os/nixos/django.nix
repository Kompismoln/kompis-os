# kompis-os/nixos/django.nix
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

  appOpts = lib'.mkAppOpts host "django" {
    options = {
      djangoApp = lib.mkOption {
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
      timeout = lib.mkOption {
        description = "Workers silent for more than this many seconds are killed and restarted.";
        type = lib.types.int;
        example = 180;
        default = 30;
      };
      celery = lib.mkEnableOption "celery et al";
    };
  };

  envs = lib.mapAttrs (
    app: appCfg:
    {
      DB_NAME = appCfg.database;
      DB_USER = appCfg.user;
      DB_HOST = "/run/postgresql";
      DEBUG = "false";
      DJANGO_SETTINGS_MODULE = "${appCfg.djangoApp}.settings";
      HOST = appCfg.endpoint;
      LOG_LEVEL = "WARNING";
      SCHEME = if appCfg.ssl then "https" else "http";
      SECRET_KEY_FILE = config.sops.secrets."${appCfg.entity}/secret-key".path;
      STATE_DIR = appCfg.home;
    }
    // (lib.optionalAttrs appCfg.celery {
      CELERY_BROKER_URL = "redis://127.0.0.1:${toString (lib'.ports "${appCfg.entity}-redis")}/0";
      FLOWER_URL_PREFIX = "/flower";
    })
  ) eachApp;

  mkDjangoManage =
    app: appCfg:
    pkgs.writeShellApplication {
      name = "${app}-manage";
      text = ''
        exec ${appCfg.packages.django-manage}/bin/manage "$@"
      '';
      runtimeEnv = envs.${app} // {
        DJANGO_APP = appCfg.packages.django-app;
        DJANGO_STATIC = appCfg.packages.django-static;
      };
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
    kompis-os.org.apps = config.kompis-os.django.apps;

    environment.systemPackages = lib.mapAttrsToList (_: bin: bin) bins;

    kompis-os.paths = lib.mapAttrs' (
      _: appCfg: lib.nameValuePair appCfg.home { inherit (appCfg) user; }
    ) eachApp;

    sops.secrets = lib.mapAttrs' (
      app: appCfg:
      lib.nameValuePair "${appCfg.entity}/secret-key" {
        sopsFile = lib'.secrets "app" appCfg.entity;
        owner = appCfg.user;
        group = appCfg.user;
      }
    ) eachApp;

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
              alias = "${appCfg.packages.django-static}/";
            };
          }
          // lib.optionalAttrs (appCfg.celery) {
            "/auth" = {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:${toString (lib'.ports app)}";
            };
            "/flower/" = {
              proxyPass = "http://localhost:${toString (lib'.ports "${app}-flower")}";
              extraConfig = ''
                auth_request /auth/;
              '';
            };
          };
      }
    ) eachApp;

    systemd.services = lib'.mergeAttrs (app: appCfg: {
      "${app}" = {
        path = [ pkgs.postgresql ];
        description = "serve ${app}";
        preStart =
          let
            query = "SELECT * FROM django_migrations WHERE name='${appCfg.migration}'";
          in
          lib.mkIf (appCfg.migration != null) (
            lib.mkBefore ''
              echo "Validating database state for ${app}..."
              psql -U "${appCfg.user}" -d "${appCfg.database}" -c "${query}" | grep -q 1;
            ''
          );
        serviceConfig = {
          ExecStart = lib.escapeShellArgs [
            "${appCfg.packages.django-app}/bin/gunicorn"
            "${appCfg.djangoApp}.wsgi:application"
            "--bind"
            "localhost:${toString (lib'.ports app)}"
            "--timeout"
            (toString appCfg.timeout)
          ];
          User = appCfg.user;
          Group = appCfg.user;
          Environment = lib'.envToList envs.${app};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${app}-celery" = lib.mkIf appCfg.celery {
        description = "start ${app}-celery";
        serviceConfig = {
          ExecStart = "${appCfg.packages.django-app}/bin/celery -A ${appCfg.djangoApp} worker -l warning";
          User = appCfg.user;
          Group = appCfg.user;
          Environment = lib'.envToList envs.${app};
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "${app}.service" ];
        requires = [ "${app}.service" ];
      };

      "${app}-flower" = lib.mkIf appCfg.celery {
        description = "start ${app}-flower";
        serviceConfig = {
          ExecStart = "${appCfg.packages.django-app}/bin/celery -A ${appCfg.djangoApp} flower --port=${toString (lib'.ports "${app}-flower")}";
          User = appCfg.user;
          Group = appCfg.user;
          Environment = lib'.envToList envs.${app};
        };
        wantedBy = [ "multi-user.target" ];
        after = [ "${app}.service" ];
        requires = [ "${app}.service" ];
      };

      "${app}-migrate" = {
        description = "migrate ${app}";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${appCfg.packages.django-app}/bin/django-admin migrate";
          User = appCfg.user;
          Group = appCfg.user;
          Environment = lib'.envToList envs.${app};
        };
      };

      "${app}-pgsql-dump" = {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-dump}/bin/pgsql-dump ${app} ${appCfg.home}";
          User = appCfg.user;
          Group = appCfg.user;
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
          ExecStart = "${pkgs.pgsql-restore}/bin/pgsql-restore ${appCfg.user} ${appCfg.home}";
          User = appCfg.user;
          Group = appCfg.user;
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
