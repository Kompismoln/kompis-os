# kompis-os/nixos/cinnamon.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kompis-os.cinnamon = {
    enable = lib.mkEnableOption "cinnamon desktop environment";
  };

  config = lib.mkIf config.kompis-os.cinnamon.enable {
    security = {
      polkit.enable = true;
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-xapp
        xdg-desktop-portal-gtk
      ];
      config = {
        x-cinnamon = {
          default = [
            "xapp"
            "gtk"
          ];
        };
      };
    };

    services = {
      tumbler.enable = true;
      gvfs.enable = true;
    };

    services.xserver = {
      enable = true;
      desktopManager.cinnamon.enable = true;
      displayManager.lightdm = {
        extraConfig = ''
          minimum-uid=1000
          maximum-uid=1999
        '';
        enable = true;
        greeters.slick.enable = true;
      };
    };
  };
}
