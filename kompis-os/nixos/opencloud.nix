{
  config,
  host,
  lib,
  lib',
  org,
  ...
}:

let
  cfg = config.kompis-os.opencloud;
  eachApp = lib.filterAttrs (_app: appCfg: appCfg.enable) cfg.apps;
  appOpts = lib'.mkAppOpts host "opencloud" { };
in
{
  options = {
    kompis-os.opencloud = {
      apps = lib.mkOption {
        type = with lib.types; attrsOf (submodule appOpts);
        default = { };
        description = "opencloud instances to serve";
      };
    };
  };

  config = lib.mkIf (eachApp != { }) {

    kompis-os.paths = lib.concatMapAttrs (app: appCfg: {
      ${appCfg.home} = { inherit (appCfg) user; };
      "/etc/${app}" = { inherit (appCfg) user; };
    }) eachApp;

    systemd.services = lib'.mergeAttrs (app: _appCfg: {
      "container@${app}" = {
        serviceConfig = {
          TimeoutStopSec = 10;
          KillMode = "mixed";
        };
      };
    }) eachApp;

    services.nginx.virtualHosts = lib.mapAttrs' (
      _app: appCfg:
      lib.nameValuePair appCfg.endpoint {
        forceSSL = appCfg.ssl;
        enableACME = appCfg.ssl;
        extraConfig = ''
          client_max_body_size 1G;
        '';

        locations = {
          "/" = {
            proxyPass = "http://127.0.0.1:${toString org.app.${appCfg.entity}.port}";
          };
        };
      }
    ) eachApp;

    containers = lib.mapAttrs (app: appCfg: {
      autoStart = true;
      ephemeral = true;

      bindMounts = {
        ${config.services.opencloud.stateDir} = {
          isReadOnly = false;
          hostPath = appCfg.home;
        };
        "/etc/opencloud" = {
          isReadOnly = false;
          hostPath = "/etc/${app}";
        };
      };

      config = {
        system.stateVersion = config.system.stateVersion;

        users.users.opencloud.uid = org.app.${appCfg.entity}.id;
        users.groups.opencloud.gid = org.app.${appCfg.entity}.id;

        services.opencloud = {
          enable = true;
          port = org.app.${appCfg.entity}.port;
          inherit (appCfg) url;
          environment = {
            OC_INSECURE = "true";
          };
        };
      };
    }) eachApp;
  };
}
