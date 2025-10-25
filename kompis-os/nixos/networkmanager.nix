{
  lib,
  config,
  ...
}:
{
  options.kompis-os.networkmanager = {
    enable = lib.mkEnableOption "networkmanager for non-DE envs";
  };

  config = lib.mkIf config.kompis-os.networkmanager.enable {

    networking.networkmanager.enable = true;

    users.groups.networkmanager.members = lib.attrNames (
      lib.filterAttrs (user: userCfg: userCfg.isNormalUser) config.users.users
    );
  };
}
