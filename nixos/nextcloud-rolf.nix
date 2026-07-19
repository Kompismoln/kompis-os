{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.o11n.nextcloud-rolf;
  eachApp = lib.filterAttrs (_: app: app.enable) cfg.apps;

  appOpts =
    { config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "nextcloud-rolf";
        name = lib.mkOption {
          description = "app name";
          type = lib.types.str;
        };
        endpoint = lib.mkOption {
          description = "app's endpoint";
          type = lib.types.str;
        };
        packages = lib.mkOption {
          description = "app package";
          type = with lib.types; attrsOf package;
        };
        home = lib.mkOption {
          description = "app's home";
          type = lib.types.str;
        };
        ssl = lib.mkOption {
          description = "force encrypted connections";
          type = lib.types.bool;
          default = true;
        };
        user = lib.mkOption {
          description = "user name";
          type = lib.types.str;
          default = config.name;
        };
        siteRoot = lib.mkOption {
          description = "Path to serve";
          type = lib.types.str;
          default = "${config.home}/_site";
        };
        sourceRoot = lib.mkOption {
          description = "Where build files are gathered at runtime";
          type = lib.types.str;
          default = "${config.home}/_src";
        };
      };
    };
in
{
  options = {
    o11n.nextcloud-rolf = {
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
        _: app:
        pkgs.runCommand app.name
          {
            src = app.packages.default;
            nativeBuildInputs = [ pkgs.makeWrapper ];
          }
          ''
            mkdir -p $out/bin

            makeWrapper \
              $src/bin/rolf \
              $out/bin/${app.name} \
                --append-flags ${app.home} \
                --append-flags ${app.sourceRoot} \
                --append-flags ${app.siteRoot} \
                --append-flags --watch
          ''
      ) eachApp;
    in
    lib.mkIf (eachApp != { }) {

      environment.systemPackages = lib.attrValues sync-commands;

      services.nginx.virtualHosts = lib.mapAttrs' (
        _: app:
        lib.nameValuePair app.endpoint {
          forceSSL = app.ssl;
          enableACME = app.ssl;

          root = app.siteRoot;
          locations."/" = {
            index = "index.html";
            tryFiles = "$uri $uri/ /404.html";
          };
        }
      ) eachApp;

      systemd.timers = lib.mapAttrs' (
        _: app:
        lib.nameValuePair "${app.name}-build" {
          description = "Scheduled building of todays articles";
          wantedBy = [ "timers.target" ];
          timerConfig = {
            OnCalendar = "01:00";
            Unit = "${app.name}-build.service";
          };
        }
      ) eachApp;

      systemd.services = lib.concatMapAttrs (_: app: {
        "${app.name}-build" = {
          description = "run ${app.name}-build";
          serviceConfig = {
            Type = "oneshot";
            ExecStart = "${app.packages.gems}/bin/jekyll build -s ${app.sourceRoot} -d ${app.siteRoot} --disable-disk-cache";
            WorkingDirectory = app.sourceRoot;
            User = app.user;
            Group = app.user;
          };
        };
        ${app.name} = {
          description = "run ${app.name}";
          serviceConfig = {
            ExecStart = "${sync-commands.${app.name}}/bin/${app.name}";
            WorkingDirectory = app.home;
            User = app.user;
            Group = app.user;
          };
          wantedBy = [ "multi-user.target" ];
        };
      }) eachApp;
    };
}
