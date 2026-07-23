{
  name,
  lib,
  host,
  config,
  context,
  ...
}:
{
  options = {
    name = lib.mkOption {
      type = lib.types.str;
      default = "${config.username}@${host.name}";
    };
    username = lib.mkOption {
      type = lib.types.str;
      default = name;
    };
    configurationFile = lib.mkOption {
      description = "path to specific configuration";
      type = lib.types.path;
      default = context.path + "/homes/${config.name}.nix";
    };
    roles = lib.mkOption {
      type = with lib.types; listOf str;
    };
    hostname = lib.mkOption {
      type = lib.types.str;
      default = host.name;
    };
    stateVersion = lib.mkOption {
      description = "nixos state version";
      type = with lib.types; nullOr str;
      default = host.stateVersion;
    };
  };
}
