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
  hostConfig = config;
in
{
  options = {
    kompis-os.mobilizon = {
      apps = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule (
            lib'.mkAppOpts host "mobilizon" {
            }
          )
        );
        default = { };
        description = "mobilizon apps to serve";
      };
    };
  };

  config = lib.mkIf (eachApp != { }) {
    kompis-os.org.apps = config.kompis-os.mobilizon.apps;

    kompis-os.paths = lib.mapAttrs' (
      _: appCfg: lib.nameValuePair appCfg.home { inherit (appCfg) user; }
    ) eachApp;

    kompis-os.preserve.directories = lib.mapAttrsToList (app: appCfg: {
      directory = appCfg.home;
      user = appCfg.user;
      group = appCfg.user;
    }) eachApp;

    services.nginx.virtualHosts = lib.mapAttrs' (
      app: appCfg:
      let
        proxyPass = "http://127.0.0.1:${toString (lib'.ports app)}";
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
          root = "${appCfg.package}/lib/mobilizon-${(appCfg.package).version}/priv/static";
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

    systemd.services = lib.mapAttrs' (
      app: appCfg:
      lib.nameValuePair "container@${app}" {
        serviceConfig = {
          TimeoutStopSec = 10;
          KillMode = "mixed";
        };
      }
    ) eachApp;

    containers = lib.mapAttrs' (
      app: appCfg:
      (lib.nameValuePair app {
        autoStart = true;
        ephemeral = true;

        bindMounts = {
          "/var/lib/mobilizon" = {
            isReadOnly = false;
            hostPath = appCfg.home;
          };
          "/run/postgresql" = {
            isReadOnly = false;
          };
        };

        config = {
          system.stateVersion = hostConfig.system.stateVersion;
          users = {
            users.mobilizon = {
              uid = lib'.ids.${app};
              group = "mobilizon";
            };
            groups.mobilizon.gid = lib'.ids.${app};
          };
          services.postgresql.enable = lib.mkForce false;
          systemd.services.mobilizon-postgresql.enable = lib.mkForce false;

          environment.systemPackages = [ pkgs.postgresql ];

          systemd.services.mobilizon = {
            path = [ pkgs.postgresql ];

            preStart =
              let
                query = "SELECT * FROM schema_migrations WHERE version=${appCfg.migration}";
              in
              lib.mkIf (appCfg.migration != null) (
                lib.mkBefore ''
                  echo "Validating database state for ${app}..."
                  psql -U "${appCfg.user}" -d "${appCfg.database}" -c "${query}" | grep -q 1;
                ''
              );
          };
          # ...
          services.mobilizon = {
            enable = true;
            inherit (appCfg) package;
            nginx.enable = false;
            settings.":mobilizon" = {
              "Mobilizon.Web.Endpoint".http = {
                port = lib'.ports app;
                ip = (settingsFormat appCfg).lib.mkTuple [
                  0
                  0
                  0
                  0
                ];
              };
              "Mobilizon.Storage.Repo" = {
                socket_dir = "/run/postgresql";
                database = appCfg.database;
                username = appCfg.user;
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
