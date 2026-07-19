{
  config,
  lib,
  org,
  ...
}:

let
  cfg = config.o11n.opencloud;
  eachApp = lib.filterAttrs (_app: appCfg: appCfg.enable) cfg.apps;
in
{
  options = {
    o11n.opencloud = {
      apps = lib.mkOption {
        type = with lib.types; attrsOf (submodule appOpts);
        default = { };
        description = "opencloud instances to serve";
      };
    };
  };

  config = lib.mkIf (eachApp != { }) {

    systemd.tmpfiles.rules = lib.concatMap (
      map (appCfg: [
        "d '${appCfg.home}' 0750 ${appCfg.user} ${appCfg.group} - -"
        "Z '${appCfg.home}' 0750 ${appCfg.user} ${appCfg.group} - -"
        "d '/etc/${appCfg.name}' 0750 ${appCfg.user} ${appCfg.group} - -"
        "Z '/etc/${appCfg.name}' 0750 ${appCfg.user} ${appCfg.group} - -"
      ]) (lib.attrValues eachApp)
    );

    systemd.services = lib.concatMapAttrs (app: _appCfg: {
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
