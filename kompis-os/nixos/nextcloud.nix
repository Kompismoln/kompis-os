{
  config,
  host,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.nextcloud;

  eachApp = lib.filterAttrs (app: appCfg: appCfg.enable) cfg.apps;

  appOpts = lib'.mkAppOpts host "nextcloud" {
    options = {
      collabora.endpoint = lib.mkOption {
        description = "collabora endpoint";
        type = with lib.types; nullOr str;
      };
    };
  };
in
{
  options = {
    kompis-os.nextcloud = {
      apps = lib.mkOption {
        type = with lib.types; attrsOf (submodule appOpts);
        default = { };
        description = "nextcloud instances to serve";
      };
    };
  };

  config = lib.mkIf (eachApp != { }) {

    kompis-os.paths = lib.mapAttrs' (
      _: appCfg: lib.nameValuePair appCfg.home { inherit (appCfg) user; }
    ) eachApp;

    sops.secrets = lib'.mergeAttrs (app: appCfg: {
      "${appCfg.entity}/secret-key" = {
        sopsFile = lib'.secrets "app" appCfg.entity;
        owner = appCfg.user;
        group = appCfg.user;
      };
    }) eachApp;

    systemd.services = lib'.mergeAttrs (app: appCfg: {

      "container@${app}" = {
        serviceConfig = {
          TimeoutStopSec = 10;
          KillMode = "mixed";
        };
      };

      "${app}-pgsql-dump" = {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${lib.getExe pkgs.bash} -c '${pkgs.postgresql}/bin/pg_dump -U ${appCfg.user} ${appCfg.database} > ${appCfg.home}/dbdump.sql'";
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
          ExecStart = "${pkgs.pgsql-restore}/bin/pgsql-restore ${app} ${appCfg.home}";
          User = appCfg.user;
          Group = appCfg.user;
        };
      };
    }) eachApp;

    systemd.timers = lib'.mergeAttrs (app: appCfg: {
      "${app}-pgsql-dump" = {
        description = "scheduled database dump";
        wantedBy = [ "timers.target" ];
        timerConfig = {
          OnCalendar = "daily";
          Unit = "${app}-pgsql-dump.service";
        };
      };
    }) eachApp;

    services.nginx.virtualHosts = lib.mapAttrs' (
      app: appCfg:
      lib.nameValuePair appCfg.endpoint {
        forceSSL = appCfg.ssl;
        enableACME = appCfg.ssl;
        extraConfig = ''
          client_max_body_size 1G;
        '';

        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:${toString (lib'.ports app)}";
          };
          "/.well-known/carddav" = {
            return = "301 $scheme://$host/remote.php/dav";
          };

          "/.well-known/caldav" = {
            return = "301 $scheme://$host/remote.php/dav";
          };
        };
      }
    ) eachApp;

    containers = lib.mapAttrs (app: appCfg: {
      autoStart = true;
      ephemeral = true;

      bindMounts = {
        ${config.services.nextcloud.home} = {
          isReadOnly = false;
          hostPath = appCfg.home;
        };
        "/run/secrets/db-password" = {
          isReadOnly = true;
          hostPath = config.sops.secrets."${appCfg.entity}/secret-key".path;
        };
        "/run/secrets/admin-password" = {
          isReadOnly = true;
          hostPath = config.sops.secrets."${appCfg.entity}/secret-key".path;
        };
      };

      config = {
        system.stateVersion = config.system.stateVersion;

        users.users.nextcloud.uid = lib'.ids.${app};
        users.groups.nextcloud.gid = lib'.ids.${app};

        environment.systemPackages = [ pkgs.postgresql ];

        services.nginx = {
          virtualHosts.localhost = {
            extraConfig = ''
              set_real_ip_from 127.0.0.1/32;
              real_ip_header X-Forwarded-For;
              real_ip_recursive on;
            '';
            listen = [
              {
                addr = "127.0.0.1";
                port = lib'.ports app;
                ssl = false;
              }
            ];
          };
        };

        systemd.services.nextcloud-setup = {
          after = [
            "redis-nextcloud.service"
          ];
          requires = [
            "redis-nextcloud.service"
          ];
        };

        services.nextcloud = {
          enable = true;
          https = true;
          hostName = "localhost";
          package = pkgs.nextcloud32;
          appstoreEnable = true;
          maxUploadSize = "1G";
          extraApps = {
            inherit (pkgs.nextcloud32Packages.apps) calendar;
          };
          settings = {
            trusted_proxies = [
              "127.0.0.1"
            ];
            trusted_domains = [
              appCfg.endpoint
              appCfg.collabora.endpoint
            ];
            default_phone_region = "SE";
            overwriteprotocol = "https";
            forwarded_for_headers = [ "HTTP_X_FORWARDED_FOR" ];
            "simpleSignUpLink.shown" = false;
          };
          phpOptions = {
            "opcache.interned_strings_buffer" = 23;
          };
          configureRedis = true;
          caching = {
            redis = true;
            memcached = true;
          };
          config = {
            dbtype = "pgsql";
            dbhost = "localhost";
            dbpassFile = "/run/secrets/db-password";
            dbuser = appCfg.user;
            dbname = appCfg.database;
            adminpassFile = "/run/secrets/admin-password";
          };
        };
      };
    }) eachApp;
  };
}
