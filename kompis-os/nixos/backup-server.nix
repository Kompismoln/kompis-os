{
  config,
  lib',
  lib,
  ...
}:
{
  options.kompis-os.backup-server = {
    enable = lib.mkEnableOption "restic rest server";
  };
  config = lib.mkIf (config.kompis-os.backup-server.enable) {
    services.restic.server = {
      enable = true;
      prometheus = true;
      listenAddress = toString lib'.ids.restic.port;
      extraFlags = [ "--no-auth" ];
    };
  };
}
