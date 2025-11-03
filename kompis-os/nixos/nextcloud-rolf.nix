{
  config,
  lib,
  lib',
  pkgs,
  host,
  ...
}:

let
  cfg = config.kompis-os.nextcloud-rolf;
  eachApp = lib.filterAttrs (app: appCfg: appCfg.enable) cfg.apps;

  appOpts = lib'.mkAppOpts host "nextcloud-rolf" {
    options = {
      siteRoot = lib.mkOption {
        description = "Path to serve";
        type = lib.types.str;
      };
      sourceRoot = lib.mkOption {
        description = "Where build files are gathered at runtime";
        type = lib.types.str;
      };
    };
  };
in
{
  options = {
    kompis-os.nextcloud-rolf = {
      apps = lib.mkOption {
        type = with lib.types; attrsOf (submodule appOpts);
        default = { };
        description = "nextcloud-rolf apps to serve";
      };
    };
  };

  config =
    let
      sync-commands = lib.mapAttrs (
        app: appCfg:
        pkgs.runCommand app
          {
            src = appCfg.package;
            nativeBuildInputs = with pkgs; [ makeWrapper ];
          }
          ''
            mkdir -p $out/bin

            makeWrapper \
              $src/bin/rolf \
              $out/bin/${app} \
                --append-flags ${appCfg.sourceRoot} \
                --append-flags ${appCfg.sourceRoot}/_src \
                --append-flags ${appCfg.siteRoot} \
                --append-flags --watch
          ''
      ) eachApp;
    in
    lib.mkIf (eachApp != { }) {

      environment.systemPackages = lib.mapAttrsToList (app: pkg: pkg) sync-commands;

      services.nginx.virtualHosts = lib.mapAttrs' (
        app: appCfg:
        lib.nameValuePair appCfg.endpoint {
          forceSSL = appCfg.ssl;
          enableACME = appCfg.ssl;

          root = appCfg.siteRoot;
          locations."/" = {
            index = "index.html";
            tryFiles = "$uri $uri/ /404.html";
          };
        }
      ) eachApp;

      systemd.timers = lib.mapAttrs' (
        app: appCfg:
        lib.nameValuePair "${app}-build" {
          description = "Scheduled building of todays articles";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "01:00";
            Unit = "${app}-build.service";
          };
        }
      ) eachApp;

      systemd.services = lib'.mergeAttrs (app: appCfg: {
        "${app}-build" = {
          description = "run ${app}-build";
          serviceConfig = {
            Type = "oneshot";
            ExecStart =
              let
                inherit (appCfg.packages) gems;
              in
              "${gems}/bin/jekyll build -s ${appCfg.sourceRoot}/_src -d ${appCfg.siteRoot} --disable-disk-cache";
            WorkingDirectory = "${appCfg.sourceRoot}/_src";
            User = appCfg.user;
            Group = appCfg.user;
          };
        };
        ${app} = {
          description = "run ${app}";
          serviceConfig = {
            ExecStart = "${sync-commands.${app}}/bin/${app}";
            WorkingDirectory = appCfg.sourceRoot;
            User = appCfg.user;
            Group = appCfg.user;
          };
          wantedBy = [ "multi-user.target" ];
        };
      }) eachApp;
    };
}
