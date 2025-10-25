{
  config,
  lib,
  lib',
  org,
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.sendmail;
  eachUser = lib.filterAttrs (user: cfg: cfg.enable) cfg;

  userOpts = {
    options = {
      enable = lib.mkEnableOption "sendmail." // {
        default = true;
      };
    };
  };
in
{
  options.kompis-os.sendmail = lib.mkOption {
    description = "Set of users to be configured with sendmail.";
    type = with lib.types; attrsOf (submodule userOpts);
    default = { };
  };

  config = lib.mkIf (eachUser != { }) {

    sops.secrets = lib.mapAttrs' (
      user: cfg:
      (lib.nameValuePair "${user}/mail" {
        sopsFile = lib'.secrets "user" user;
        owner = user;
        group = user;
      })
    ) eachUser;

    programs.msmtp = {
      enable = true;
      defaults = {
        port = 587;
        host = org.mailserver.int;
        tls = true;
        logfile = "~/.msmtp.log";
      };
      accounts = lib.mapAttrs (user: cfg: {
        host = org.mailserver.ext;
        auth = true;
        user = "${user}@${org.domain}";
        from = "${user}@${org.domain}";
        passwordeval = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."${user}/mail".path}";
      }) eachUser;
    };
  };
}
