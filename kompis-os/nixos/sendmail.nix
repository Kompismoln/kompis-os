{
  config,
  lib,
  org,
  pkgs,
  ...
}:

let
  eachUser = lib.filterAttrs (
    user: userCfg: userCfg.isNormalUser && org.user.${user}.mail
  ) config.users.users;
  cfg = config.kompis-os.sendmail;
in
{
  options.kompis-os.sendmail.enable = lib.mkEnableOption "sendmail";

  config = lib.mkIf cfg.enable {

    sops.secrets = lib.mapAttrs' (
      user: _userCfg:
      (lib.nameValuePair "${user}/mail" {
        inherit (org.user.${user}.secrets) sopsFile;
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
      // lib.mapAttrs (user: _userCfg: {
        port = 587;
        tls = true;
        logfile = "~/.msmtp.log";
        host = org.mailserver.ext;
        auth = true;
        user = "${user}@${org.endpoint}";
        from = "${user}@${org.endpoint}";
        passwordeval = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."${user}/mail".path}";
      }) eachUser;
    };
  };
}
