{
  config,
  lib,
  lib',
  ...
}:

let
  inherit (lib)
    filterAttrs
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.kompis-os.backup;
  eachTarget = filterAttrs (user: cfg: cfg.enable) cfg;
  repoOptions =
    { config, ... }:
    {
      options = with types; {
        enable = mkEnableOption ''this backup target'';
        repo = mkOption {
          type = str;
          default = config._module.args.name;
          description = "Name for restic repository.";
        };
        paths = mkOption {
          type = listOf str;
          default = [ ];
        };
        target = mkOption {
          type = str;
          default = "localhost";
        };
      };
    };
in
{
  options.kompis-os.backup = {
    km = mkOption {
      type = types.submodule repoOptions;
      default = { };
      description = ''Definition of `km` backup target.'';
    };
  };

  config = mkIf (eachTarget != { }) {

    sops.secrets."backup/secret-key" = {
      sopsFile = ../../enc/service-backup.yaml;
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
