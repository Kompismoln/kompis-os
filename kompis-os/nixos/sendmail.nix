{
  config,
  lib,
  lib',
  org,
  pkgs,
  ...
}:

let
  eachUser = lib.filterAttrs (_: userCfg: userCfg.mail) org.user;
  cfg = config.kompis-os.sendmail;
in
{
  options.kompis-os.sendmail.enable = lib.mkEnableOption "sendmail";

  config = lib.mkIf cfg.enable {

    sops.secrets = lib.mapAttrs' (
      user: userCfg:
      (lib.nameValuePair "${user}/mail" {
        sopsFile = lib'.secrets "user" user;
        owner = user;
        group = user;
      })
    ) eachUser;

    programs.msmtp = {
      enable = true;

      accounts = {
        default = {
          user = "someone";
          from = "someone";
          host = org.mailserver.int;
        };
      }
      // lib.mapAttrs (user: userCfg: {
        port = 587;
        tls = true;
        logfile = "~/.msmtp.log";
        host = org.mailserver.ext;
        auth = true;
        user = "${user}@${org.domain}";
        from = "${user}@${org.domain}";
        passwordeval = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."${user}/mail".path}";
      }) eachUser;
    };
  };
}
