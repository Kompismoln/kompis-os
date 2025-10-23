{
  config,
  lib,
  lib',
  org,
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    types
    ;

  cfg = config.kompis-os.sendmail;
  eachUser = filterAttrs (user: cfg: cfg.enable) cfg;

  userOpts = {
    options = {
      enable = mkEnableOption "sendmail." // {
        default = true;
      };
    };
  };
in
{
  options.kompis-os.sendmail =
    with types;
    mkOption {
      description = "Set of users to be configured with sendmail.";
      type = attrsOf (submodule userOpts);
      default = { };
    };

  config = mkIf (eachUser != { }) {

    sops.secrets = mapAttrs' (
      user: cfg:
      (nameValuePair "${user}/mail" {
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
      accounts = mapAttrs (user: cfg: {
        host = org.mailserver.ext;
        auth = true;
        user = "${user}@${org.domain}";
        from = "${user}@${org.domain}";
        passwordeval = "${pkgs.coreutils}/bin/cat ${config.sops.secrets."${user}/mail".path}";
      }) eachUser;
    };
  };
}
