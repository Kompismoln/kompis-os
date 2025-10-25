{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.kompis-os.mysql;
in
{
  options.kompis-os.mysql = {
    enable = lib.mkEnableOption "mysql";
  };

  config = lib.mkIf (cfg.enable) {
    kompis-os.preserve.databases = [
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
