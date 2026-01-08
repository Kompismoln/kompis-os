{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kompis-os.networkmanager = {
    enable = lib.mkEnableOption "avahi printer discovery";
  };
  config = {
    services.avahi = {
      enable = true;
      openFirewall = true;
    };

    services.printing = {
      enable = true;
      drivers = with pkgs; [
        cups-filters
        cups-browsed
      ];
    };

    environment.systemPackages = with pkgs; [
      system-config-printer
    ];

    users.groups.lpadmin.members = lib.attrNames (
      lib.filterAttrs (user: userCfg: userCfg.isNormalUser) config.users.users
    );
  };
}
