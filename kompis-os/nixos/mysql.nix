{
  config,
  pkgs,
  lib,
  options,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrsToList
    mkIf
    mkOption
    types
    ;

  cfg = config.kompis-os.mysql;
  eachCfg = filterAttrs (user: cfg: cfg.ensure) cfg;
  userOpts = {
    options = with types; {
      ensure = mkOption {
        description = "Ensure mysql database for the user";
        default = true;
        type = bool;
      };
    };
  };
in
{
  options.kompis-os.mysql = mkOption {
    type = with lib.types; attrsOf (submodule userOpts);
    default = { };
    description = "Specification of one or more mysql user/database pair to setup";
  };

  config = mkIf (eachCfg != { }) {
    kompis-os.preserve.databases = [
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
      }
    ];
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
      ensureUsers = mapAttrsToList (user: cfg: {
        name = user;
        ensurePermissions = {
          "\\`${user}\\`.*" = "ALL PRIVILEGES";
        };
      }) eachCfg;
    };
  };
}
