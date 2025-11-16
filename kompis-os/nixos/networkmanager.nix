{
  lib,
  config,
  ...
}:
{
  options.kompis-os.networkmanager = {
    enable = lib.mkEnableOption "networkmanager for non-DE envs";
  };

  imports = [
    ../nixos/preserve.nix
  ];

  config = lib.mkIf config.kompis-os.networkmanager.enable {

    networking.networkmanager.enable = true;

    kompis-os.preserve = {
      directories = lib.optionals config.networking.networkmanager.enable [
        "/etc/NetworkManager"
      ];
    };

    users.groups.networkmanager.members = lib.attrNames (
      lib.filterAttrs (user: userCfg: userCfg.isNormalUser) config.users.users
    );
  };
}
