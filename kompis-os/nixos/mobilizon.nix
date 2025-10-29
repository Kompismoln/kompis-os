{
  config,
  host,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.mobilizon;
  settingsFormat = appCfg: pkgs.formats.elixirConf { elixir = appCfg.package.elixirPackage; };

  eachApp = lib.filterAttrs (app: appCfg: appCfg.enable) cfg.apps;
  stateDir = app: "/var/lib/${app}/mobilizon";
  hostConfig = config;
in
{
  options = {
    kompis-os.mobilizon = {
      apps = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule (lib'.mkAppOpts host "mobilizon" { }));
        default = { };
        description = "Specification of one or more mobilizon apps to serve";
      };
    };
  };

  config = lib.mkIf (eachApp != { }) {

    kompis-os.preserve.directories = lib.mapAttrsToList (app: appCfg: {
      directory = stateDir app;
      user = app;
      group = app;
    }) eachApp;

    kompis-os.users = lib.mapAttrs' (
      app: appCfg:
      lib.nameValuePair app {
        class = "app";
        publicKey = false;
      }
    ) eachApp;

    systemd.tmpfiles.rules = lib.flatten (
      lib.mapAttrsToList (app: appCfg: [
        "d '${stateDir app}' 0750 ${app} ${app} - -"
        "Z '${stateDir app}' 0750 ${app} ${app} - -"
      ]) eachApp
    );

    systemd.services = lib'.mergeAttrs (app: appCfg: {
      "${app}-pgsql-dump" = {
        description = "dump a snapshot of the postgresql database";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.pgsql-dump}/bin/pgsql-dump ${app} ${stateDir app}";
          User = app;
          Group = app;
        };
      };

      "${app}-pgsql-restore" = {
        description = "restore postgresql database from snapshot";
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
      let
        proxyPass = "http://127.0.0.1:${toString appCfg.port}";
      in
      lib.nameValuePair appCfg.endpoint {
        forceSSL = appCfg.ssl;
        enableACME = appCfg.ssl;

        locations = {
          "/" = {
            inherit proxyPass;
            recommendedProxySettings = lib.mkDefault true;
            extraConfig = ''
              expires off;
              add_header Cache-Control "public, max-age=0, s-maxage=0, must-revalidate" always;
            '';
          };
        };
        locations."~ ^/(assets|img)" = {
          root = "${appCfg.package}/lib/mobilizon-${appCfg.package.version}/priv/static";
          extraConfig = ''
            access_log off;
            add_header Cache-Control "public, max-age=31536000, s-maxage=31536000, immutable";
          '';
        };
        locations."~ ^/(media|proxy)" = {
          inherit proxyPass;
          recommendedProxySettings = lib.mkDefault true;
          extraConfig = ''
            proxy_http_version 1.1;
            proxy_request_buffering off;
            access_log off;
            add_header Cache-Control "public, max-age=31536000, s-maxage=31536000, immutable";
          '';
        };
      }
    ) eachApp;

    containers = lib.mapAttrs' (
      app: appCfg:
      (lib.nameValuePair app {
        autoStart = true;

        bindMounts = {
          "/var/lib/mobilizon" = {
            isReadOnly = false;
            hostPath = stateDir app;
          };
        };

        config = {
          system.stateVersion = hostConfig.system.stateVersion;
          users = {
            users.mobilizon = {
              uid = appCfg.uid;
              group = "mobilizon";
            };
            groups.mobilizon.gid = appCfg.uid;
          };
          services.mobilizon = {
            enable = true;
            inherit (appCfg) package;
            nginx.enable = false;
            settings.":mobilizon" = {
              "Mobilizon.Web.Endpoint".http = {
                port = lib.mkForce appCfg.port;
                ip = (settingsFormat appCfg).lib.mkTuple [
                  0
                  0
                  0
                  0
                ];
              };
              "Mobilizon.Storage.Repo" = {
                hostname = "127.0.0.1";
                database = app;
                username = app;
                password = app;
                socket_dir = null;
              };
              ":instance" = {
                name = app;
                hostname = appCfg.endpoint;
              };
            };

          };
        };

      })
    ) eachApp;
  };
}
