{
  config,
  lib,
  lib',
  ...
}:

let
  inherit (lib)
    mkIf
    mkEnableOption
    mkOption
    types
    ;
  cfg = config.kompis-os.backup-server;
in
{
  options.kompis-os.backup-server = {
    enable = mkEnableOption ''a restic rest server on this host'';
    port = mkOption {
      type = types.port;
      default = lib'.ids.restic.port;
    };
  };
  config = mkIf (cfg.enable) {

    services.restic.server = {
      enable = true;
      prometheus = true;
      listenAddress = toString cfg.port;
      extraFlags = [ "--no-auth" ];
    };
  };
}
