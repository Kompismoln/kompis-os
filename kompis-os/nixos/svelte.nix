# kompis-os/nixos/svelte.nix
{
  config,
  host,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.svelte;
  eachApp = lib.filterAttrs (endpoint: cfg: cfg.enable) cfg.apps;

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

  envs = lib.mapAttrs (app: appCfg: {
    ORIGIN = "${if appCfg.ssl then "https" else "http"}://${appCfg.endpoint}";
    PUBLIC_API = appCfg.api;
    PUBLIC_API_SSR = appCfg.ssr;
    PORT = toString (lib'.ports app);
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
      app: appCfg:
      lib.nameValuePair appCfg.endpoint {
        forceSSL = appCfg.ssl;
        enableACME = appCfg.ssl;
        locations."${appCfg.location}" = {
          recommendedProxySettings = true;
          proxyPass = "http://127.0.0.1:${toString (lib'.ports app)}";
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
