{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.kompis-os.hyprland = {
    enable = lib.mkEnableOption "hyprland";
  };

  config = lib.mkIf config.kompis-os.hyprland.enable {

    programs = {
      hyprland.enable = true;
      hyprlock.enable = true;
      uwsm = {
        enable = true;
        waylandCompositors.hyprland = {
          prettyName = "Hyprland";
          comment = "Hyprland compositor managed by UWSM";
          binPath = "/run/current-system/sw/bin/Hyprland";
        };
      };
    };

    services.hypridle.enable = true;

    environment.sessionVariables.NIXOS_OZONE_WL = "1";

    security.polkit.enable = true;

    xdg.portal = {
      enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      config.common.default = "*";
    };
  };
}
