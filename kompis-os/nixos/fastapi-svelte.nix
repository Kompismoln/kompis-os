{ config, lib, ... }:

let
  cfg = config.kompis-os.fastapi-svelte;
  eachSite = lib.filterAttrs (hostname: cfg: cfg.enable) cfg.sites;
  siteOpts = {
    options = {
      enable = lib.mkEnableOption "FastAPI+SvelteKit app";
      ssl = lib.mkOption {
        description = "Whether to enable SSL (https) support.";
        type = lib.types.bool;
      };
      ports = lib.mkOption {
        description = "Listening ports.";
        type = with lib.types; listOf port;
      };
      appname = lib.mkOption {
        description = "Internal namespace";
        type = lib.types.str;
      };
      hostname = lib.mkOption {
        description = "Network namespace";
        type = lib.types.str;
      };
    };
  };
in
{
  options.kompis-os.fastapi-svelte = {
    sites = lib.mkOption {
      description = "Definition of per-domain FastAPI+SvelteKit apps to serve.";
      type = with lib.types; attrsOf (submodule siteOpts);
      default = { };
    };
  };

  config = lib.mkIf (eachSite != { }) {
    kompis-os.fastapi.sites = lib.mapAttrs (name: cfg: {
      enable = cfg.enable;
      appname = cfg.appname;
      hostname = cfg.hostname;
      port = builtins.elemAt cfg.ports 0;
      ssl = cfg.ssl;
    }) eachSite;

    kompis-os.svelte.sites = lib.mapAttrs (name: cfg: {
      enable = cfg.enable;
      appname = cfg.appname;
      hostname = cfg.hostname;
      port = builtins.elemAt cfg.ports 1;
      ssl = cfg.ssl;
      api = "${if cfg.ssl then "https" else "http"}://${cfg.hostname}";
      api_ssr = "http://localhost:${toString (builtins.elemAt cfg.ports 0)}";
    }) eachSite;
  };
}
