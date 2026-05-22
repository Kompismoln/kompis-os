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

  eachApp = lib.filterAttrs (_: appCfg: appCfg.enable) cfg.apps;

  appOpts = lib'.mkAppOpts host "django" {
    options = {
      djangoApp = lib.mkOption {
        description = "django app name";
        type = lib.types.str;
        default = "django";
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

  envs = lib.mapAttrs (app: appCfg: {
    DB_NAME = appCfg.database;
    DB_USER = appCfg.user;
    DB_HOST = "/run/postgresql";
    DEBUG = "false";
    DJANGO_SETTINGS_MODULE = "${appCfg.djangoApp}.settings";
    HOST = appCfg.endpoint;
    DJANGO_MODE = "main";
    DJANGO_LOG_LEVEL = "WARNING";
    SCHEME = if appCfg.ssl then "https" else "http";
    SECRET_KEY_FILE = config.sops.secrets."${appCfg.entity}/secret-key".path;
    STATIC_URL = appCfg.locationStatic;
    STATE_DIR = appCfg.home;
    STATIC_ROOT = statics.${app};
  }) eachApp;

  mkCollectStatic =
    app: appCfg:
    pkgs.runCommand "${app}-static" { } ''
      export STATIC_ROOT="$out"
      export STATIC_URL="${appCfg.locationStatic}"
      export DJANGO_MODE="collectstatic"
      export DJANGO_SETTINGS_MODULE=${appCfg.djangoApp}.settings
      ${appCfg.packages.django-app}/bin/django-admin collectstatic --no-input
    '';

  statics = lib.mapAttrs mkCollectStatic eachApp;

  scripts = lib.mapAttrs (
    app: appCfg: lib'.wrapBins pkgs appCfg.packages.scripts envs.${app}
  ) eachApp;

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

    environment.systemPackages = lib.mapAttrsToList (_: script: script) scripts;

    kompis-os.paths = lib.mapAttrs' (
      _: appCfg: lib.nameValuePair appCfg.home { inherit (appCfg) user; }
    ) eachApp;

    sops.secrets = lib.mapAttrs' (
      _: appCfg:
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
              alias = "${statics.${app}}/";
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
    }) eachApp;

  };
}
