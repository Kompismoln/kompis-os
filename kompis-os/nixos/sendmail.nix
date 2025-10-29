{
  config,
  lib,
  lib',
  org,
  pkgs,
  ...
}:

let
  eachUser = lib.filterAttrs (
    user: userCfg: userCfg.isNormalUser && org.user.${user} ? mail
  ) config.users.users;
in
{
  options.kompis-os.sendmail = lib.mkEnableOption "sendmail";

  config = lib.mkIf (eachUser != { }) {

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
