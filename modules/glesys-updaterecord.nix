{
  config,
  lib,
  pkgs,
  org,
  ...
}:

let
  inherit (lib)
    getExe
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.kompis-os.glesys.updaterecord;
in
{

  options.kompis-os.glesys.updaterecord = with types; {
    enable = mkEnableOption "updating DNS-record on glesys";
    recordid = mkOption {
      description = "The glesys id of the record";
      type = str;
    };
    device = mkOption {
      description = "Device that should be watched.";
      example = "enp3s0";
      type = str;
    };
  };

  config = mkIf cfg.enable {

    sops.secrets."glesys-api/secret-key" = {
      sopsFile = ../enc/service-glesys-api.yaml;
      owner = "root";
      group = "root";
    };

    systemd.services."glesys-updaterecord" = {
      description = "update A record for stationary.kompismoln.se";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig =
        let
          user = "${org.service.glesys-api.account}:$(<${config.sops.secrets."glesys-api/secret-key".path})";
          data = "recordid=${cfg.recordid}&data=$ipv4";
          url = "${org.service.glesys-api.endpoint}/domain/updaterecord";
        in
        {
          ExecStart = pkgs.writeShellScript "glesys-updaterecord" ''
            ipv4="$(${pkgs.iproute2}/bin/ip -4 -o addr show ${cfg.device} | ${pkgs.gawk}/bin/awk '{split($4, a, "/"); print a[1]}')"
            ${getExe pkgs.curl} -sSX POST -d "${data}" -u ${user} ${url} | ${pkgs.util-linux}/bin/logger -t dhcpcd
          '';
        };
    };

    systemd.timers."glesys-updaterecord" = {
      description = "update A record for stationary.ahbk.se every 10 minutes";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "10min";
      };
    };
  };
}
