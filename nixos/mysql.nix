{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.o11n.mysql;
in
{
  options.o11n.mysql = {
    enable = lib.mkEnableOption "mysql";
  };

  config = lib.mkIf (cfg.enable) {
    o11n.preserve.databases = [
      {
        directory = "/var/lib/mysql";
        user = "mysql";
        group = "mysql";
      }
    ];
    services.mysql = {
      enable = true;
      package = pkgs.mariadb;
    };
  };
}
