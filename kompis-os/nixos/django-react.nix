{ config, lib, ... }:

let
  cfg = config.kompis-os.django-react;
  eachSite = lib.filterAttrs (hostname: cfg: cfg.enable) cfg.sites;

  siteOpts = {
    options = {
      enable = lib.mkEnableOption "Django+React app";
      ports = lib.mkOption {
        description = "Listening ports.";
        type = with lib.types; listOf port;
      };
      ssl = lib.mkOption {
        description = "Whether to enable SSL (https) support.";
        type = lib.types.bool;
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
  options.kompis-os.django-react = {
    sites = lib.mkOption {
      description = "Definition of per-domain Django+React apps to serve.";
      type = with lib.types; attrsOf (submodule siteOpts);
      default = { };
    };
  };

  config = lib.mkIf (eachSite != { }) {

    kompis-os.django.sites = lib.mapAttrs (name: cfg: {
      enable = cfg.enable;
      appname = cfg.appname;
      hostname = cfg.hostname;
      port = builtins.elemAt cfg.ports 0;
      ssl = cfg.ssl;
    }) eachSite;

    kompis-os.react.sites = lib.mapAttrs (name: cfg: {
      enable = cfg.enable;
      ssl = cfg.ssl;
      api = "${if cfg.ssl then "https" else "http"}://${cfg.hostname}/api";
      appname = cfg.appname;
      hostname = cfg.hostname;
    }) eachSite;
  };
}
