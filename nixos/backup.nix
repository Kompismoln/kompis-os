{
  config,
  lib,
  org,
  ...
}:

let
  cfg = config.o11n.backup;
  eachTarget = lib.filterAttrs (_: cfg: cfg.enable) cfg;
  repoOptions =
    { config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "this backup target";
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
  options.o11n.backup = {
    km = lib.mkOption {
      type = lib.types.submodule repoOptions;
      default = { };
      description = "Definition of `km` backup target.";
    };
  };

  config = lib.mkIf (eachTarget != { }) {

    sops.secrets."backup/secret-key" = {
      inherit (org.service.backup.secrets) sopsFile;
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
      repository = "rest:http://${cfg.km.target}:asdf/repository";
      passwordFile = config.sops.secrets."backup/secret-key".path;
    };
  };
}
