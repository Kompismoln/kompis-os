# kompis-os/nixos/svelte.nix
{
  config,
  host,
  lib,
  lib',
  pkgs,
  org,
  ...
}:

let
  cfg = config.kompis-os.svelte;
  eachApp = lib.filterAttrs (_: cfg: cfg.enable) cfg.apps;

  appOpts = lib'.mkAppOpts host "svelte" (
    { config, ... }:
    {
      options = {
        api = lib.mkOption {
          description = "API root";
          type = lib.types.str;
          default = "${if config.ssl then "https" else "http"}://${config.endpoint}";
        };
        ssr = lib.mkOption {
          description = "Server side URL for the API endpoint";
          type = lib.types.str;
        };
      };
    }
  );

  sveltePkgs =
    app: appCfg:
    appCfg.packages.svelte-app.overrideAttrs {
      env = envs.${app};
    };

  envs = lib.mapAttrs (_app: appCfg: {
    ORIGIN = "${if appCfg.ssl then "https" else "http"}://${appCfg.endpoint}";
    PUBLIC_API = appCfg.api;
    PUBLIC_API_SSR = appCfg.ssr;
    PORT = toString org.app.${appCfg.entity}.port;
  }) eachApp;
in
{

  options = {
    kompis-os.svelte = {
      apps = lib.mkOption {
        type = with lib.types; attrsOf (submodule appOpts);
        default = { };
        description = "Specification of one or more Svelte apps to serve";
      };
    };
  };

  config = lib.mkIf (eachApp != { }) {
    services.nginx.virtualHosts = lib.mapAttrs' (
      _app: appCfg:
      lib.nameValuePair appCfg.endpoint {
        forceSSL = appCfg.ssl;
        enableACME = appCfg.ssl;
        locations."${appCfg.location}" = {
          recommendedProxySettings = true;
          proxyPass = "http://127.0.0.1:${toString org.app.${appCfg.entity}.port}";
        };
      }
    ) eachApp;

    systemd.services = lib.mapAttrs (app: appCfg: {
      description = "serve ${app}";
      serviceConfig = {
        ExecStart = "${pkgs.nodejs_20}/bin/node ${sveltePkgs app appCfg}/build";
        Environment = lib'.envToList envs.${app};
        User = appCfg.user;
        Group = appCfg.user;
      };
      wantedBy = [ "multi-user.target" ];
    }) eachApp;
  };
}
