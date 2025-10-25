{
  config,
  host,
  inputs,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.django;

  eachSite = lib.filterAttrs (name: cfg: cfg.enable) cfg.sites;
  eachCelery = lib.filterAttrs (name: cfg: cfg.celery.enable) eachSite;

  stateDir = appname: "/var/lib/${appname}/django";

  siteOpts =
    { name, ... }:
    {
      config.appname = lib.mkDefault name;
      options = {
        enable = lib.mkEnableOption "Django app";
        port = lib.mkOption {
          description = "Listening port.";
          example = 8000;
          type = lib.types.port;
        };
        ssl = lib.mkOption {
          description = "Whether to enable SSL (https) support.";
          default = true;
          type = lib.types.bool;
        };
        hostname = lib.mkOption {
          description = "Namespace identifying the service externally on the network.";
          type = lib.types.str;
        };
        appname = lib.mkOption {
          description = "Namespace identifying the app on the system (user, logging, database, paths etc.)";
          type = lib.types.str;
        };
        packagename = lib.mkOption {
          description = "The python name of the django application";
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
          enable = lib.mkEnableOption "Celery";
          port = lib.mkOption {
            description = "Listening port for message broker.";
            type = with lib.types; nullOr port;
            default = null;
          };
        };
      };
    };

  envs = lib.mapAttrs (
    name: cfg:
    {
      DB_NAME = "${cfg.appname}-django";
      DB_USER = "${cfg.appname}-django";
      DB_HOST = "/run/postgresql";
      DEBUG = "false";
      DJANGO_SETTINGS_MODULE = "${cfg.packagename}.settings";
      HOST = cfg.hostname;
      LOG_LEVEL = "WARNING";
      SCHEME = if cfg.ssl then "https" else "http";
      SECRET_KEY_FILE = config.sops.secrets."${cfg.appname}-django/secret-key".path;
      STATE_DIR = stateDir cfg.appname;
    }
    // (lib.optionalAttrs cfg.celery.enable {
      CELERY_BROKER_URL = "redis://127.0.0.1:${toString lib'.ids."${cfg.appname}-redis".port}/0";
      FLOWER_URL_PREFIX = "/flower";
    })
  ) eachSite;

  bins = lib.mapAttrs (
    name: cfg:
    inputs.${cfg.appname}.lib.${host.system}.mkDjangoManage {
      runtimeEnv = envs.${cfg.appname};
    }
  ) eachSite;
in
{

  options.kompis-os.django = {
    sites = lib.mkOption {
      type = with lib.types; attrsOf (submodule siteOpts);
      default = { };
      description = "Definition of per-domain Django apps to serve.";
    };
  };

  config = lib.mkIf (eachSite != { }) {

    environment.systemPackages = lib.mapAttrsToList (name: bin: bin) bins;

    kompis-os.preserve.directories = lib.mapAttrsToList (name: cfg: {
      directory = stateDir cfg.appname;
      how = "symlink";
      user = "${cfg.appname}-django";
      group = "${cfg.appname}-django";
    }) eachSite;

    sops.secrets = lib.mapAttrs' (
      name: cfg:
      lib.nameValuePair "${cfg.appname}-django/secret-key" {
        sopsFile = lib'.secrets "service" "${cfg.appname}-django";
        owner = "${cfg.appname}-django";
        group = "${cfg.appname}-django";
      }
    ) eachSite;

    kompis-os.redis.servers = lib.mapAttrs (name: cfg: {
      enable = true;
    }) eachCelery;

    kompis-os.users = lib.mapAttrs' (
      name: cfg:
      lib.nameValuePair "${cfg.appname}-django" {
        class = "service";
        publicKey = false;
      }
    ) eachSite;

    services.nginx.virtualHosts = lib.mapAttrs' (
      name: cfg:
      lib.nameValuePair cfg.hostname {
        forceSSL = cfg.ssl;
        enableACME = cfg.ssl;
        locations =
          lib.optionalAttrs (cfg.locationProxy != "") {
            ${cfg.locationProxy} = {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:${toString lib'.ids."${cfg.appname}-django".port}";
            };
          }
          // lib.optionalAttrs (cfg.locationStatic != "") {
            ${cfg.locationStatic} = {
              alias = "${inputs.${cfg.appname}.packages.${host.system}.django-static}/";
            };
          }
          // lib.optionalAttrs (cfg.celery.enable) {
            "/auth" = {
              recommendedProxySettings = true;
              proxyPass = "http://localhost:${toString lib'.ids."${cfg.appname}-django".port}";
            };
            "/flower/" = {
              proxyPass = "http://localhost:5555";
              extraConfig = ''
                auth_request /auth/;
              '';
            };
          };
      }
    ) eachSite;

    systemd.services = lib'.mergeAttrs (name: cfg: {
      "${cfg.appname}-django" = {
        description = "serve ${cfg.appname}-django";
        serviceConfig = {
          ExecStart = "${
            inputs.${cfg.appname}.packages.${host.system}.django-app
          }/bin/gunicorn ${cfg.packagename}.wsgi:application --bind localhost:${
            toString lib'.ids."${cfg.appname}-django".port
          }";
          User = "${cfg.appname}-django";
          Group = "${cfg.appname}-django";
          Environment = lib'.envToList envs.${cfg.appname};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${cfg.appname}-celery" = lib.mkIf cfg.celery.enable {
        description = "start ${cfg.appname}-celery";
        serviceConfig = {
          ExecStart = "${
            inputs.${cfg.appname}.packages.${host.system}.django-app
          }/bin/celery -A ${cfg.packagename} worker -l warning";
          User = "${cfg.appname}-django";
          Group = "${cfg.appname}-django";
          Environment = lib'.envToList envs.${cfg.appname};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${cfg.appname}-flower" = lib.mkIf cfg.celery.enable {
        description = "start ${cfg.appname}-flower";
        serviceConfig = {
          ExecStart = "${
            inputs.${cfg.appname}.packages.${host.system}.django-app
          }/bin/celery -A ${cfg.packagename} flower --port=5555";
          User = "${cfg.appname}-django";
          Group = "${cfg.appname}-django";
          Environment = lib'.envToList envs.${cfg.appname};
        };
        wantedBy = [ "multi-user.target" ];
      };

      "${cfg.appname}-django-migrate" = {
        description = "migrate ${cfg.appname}-django";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${inputs.${cfg.appname}.packages.${host.system}.django-app}/bin/django-admin migrate";
          User = "${cfg.appname}-django";
          Group = "${cfg.appname}-django";
          Environment = lib'.envToList envs.${cfg.appname};
        };
      };
      "${cfg.appname}-pgsql-dump" = {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-dump}/bin/pgsql-dump ${cfg.appname}-django ${stateDir cfg.appname}";
          User = "${cfg.appname}-django";
          Group = "${cfg.appname}-django";
        };
      };
      "${cfg.appname}-pgsql-restore" = {
        description = "restore postgresql database from snapshot";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-restore}/bin/pgsql-restore ${cfg.appname}-django ${stateDir cfg.appname}";
          User = "${cfg.appname}-django";
          Group = "${cfg.appname}-django";
        };
      };
    }) eachSite;

    systemd.timers = lib'.mergeAttrs (name: cfg: {
      "${cfg.appname}-pgsql-dump" = {
        description = "Scheduled PostgreSQL database dump";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "${cfg.appname}-pgsql-dump.service";
        };
      };
    }) eachSite;

    # maybe gate this? maybe offer restore as well, probably none though.
    #system.activationScripts = mapAttrs (name: cfg: {
    #  text = ''
    #    ${pkgs.systemd}/bin/systemctl start ${cfg.appname}-django-migrate
    #  '';
    #}) eachSite;
  };
}
