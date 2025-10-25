{
  config,
  lib,
  lib',
  ...
}:

let
  cfg = config.kompis-os.backup;
  eachTarget = lib.filterAttrs (user: cfg: cfg.enable) cfg;
  repoOptions =
    { config, ... }:
    {
      options = {
        enable = lib.mkEnableOption ''this backup target'';
        repo = lib.mkOption {
          type = lib.types.str;
          default = config._module.args.name;
          description = "Name for restic repository.";
        };
        paths = lib.mkOption {
          type = with lib.types; listOf str;
          default = [ ];
        };
        target = lib.mkOption {
          type = lib.types.str;
          default = "localhost";
        };
      };
    };
in
{
  options.kompis-os.backup = {
    km = lib.mkOption {
      type = lib.types.submodule repoOptions;
      default = { };
      description = ''Definition of `km` backup target.'';
    };
  };

  config = lib.mkIf (eachTarget != { }) {

    sops.secrets."backup/secret-key" = {
      sopsFile = lib'.secrets "service" "backup";
    };

    services.restic.backups.km = {
      paths = cfg.km.paths;
      exclude = [ ];
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 5"
        "--keep-monthly 12"
        "--keep-yearly 1"
      ];
      timerConfig = {
        OnCalendar = "*-*-* 01:00:00";
        Persistent = true;
      };
      repository = "rest:http://${cfg.km.target}:${toString lib'.ids.restic.port}/repository";
      passwordFile = config.sops.secrets."backup/secret-key".path;
    };
  };
}
