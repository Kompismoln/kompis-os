{
  config,
  lib,
  org,
  ...
}:
let
  cfg = config.kompis-os.fail2ban;
in
{
  options.kompis-os.fail2ban = {
    enable = lib.mkEnableOption "the jails configured with `services.fail2ban.jails`";
  };

  config = lib.mkIf cfg.enable {
    services.fail2ban = {
      enable = true;
      maxretry = 1;
      bantime = "1d";
      bantime-increment.enable = true;
      ignoreIP = lib.mapAttrsToList (subnet: subnetCfg: subnetCfg.address) org.subnet;
    };
  };
}
