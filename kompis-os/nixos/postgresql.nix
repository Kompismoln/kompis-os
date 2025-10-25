{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.postgresql;
in
{
  options.kompis-os.postgresql = {
    enable = lib.mkEnableOption "postgresql";
  };

  config = lib.mkIf cfg.enable {
    kompis-os.preserve.databases = [
      {
        directory = "/var/lib/postgresql";
        user = "postgres";
        group = "postgres";
      }
    ];
    services.postgresql = {
      extensions =
        ps: with ps; [
          postgis
          pg_repack
        ];
      enable = true;
      package = pkgs.postgresql_17;
    };
  };
}
