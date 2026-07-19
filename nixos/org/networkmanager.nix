{
  lib,
  config,
  ...
}:
{
  imports = [
    ../preserve.nix
  ];

  networking.networkmanager.enable = true;

  kompis-os.preserve = {
    directories = lib.optionals config.networking.networkmanager.enable [
      "/etc/NetworkManager"
    ];
  };

  users.groups.networkmanager.members = lib.attrNames (
    lib.filterAttrs (_: userCfg: userCfg.isNormalUser) config.users.users
  );
}
