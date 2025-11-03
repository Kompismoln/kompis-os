# kompis-os/nixos/paths.nix
{ config, lib, ... }:
{
  options.kompis-os.paths = lib.mkOption {
    default = { };
    type =
      with lib.types;
      attrsOf (
        submodule (
          { name, config, ... }:
          {
            options = {
              user = lib.mkOption {
                type = lib.types.str;
              };
              path = lib.mkOption {
                type = lib.types.str;
                default = name;
              };
              group = lib.mkOption {
                type = lib.types.str;
                default = config.user;
              };
              mode = lib.mkOption {
                type = lib.types.str;
                default = "0750";
              };
            };
          }
        )
      );
  };
  config = {
    systemd.tmpfiles.rules = lib.flatten (
      lib.mapAttrsToList (_: pathCfg: [
        "d '${pathCfg.path}' ${pathCfg.mode} ${pathCfg.user} ${pathCfg.group} - -"
        "Z '${pathCfg.path}' ${pathCfg.mode} ${pathCfg.user} ${pathCfg.group} - -"
      ]) config.kompis-os.paths
    );
  };
}
