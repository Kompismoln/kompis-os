{
  config,
  lib,
  org,
  pkgs,
  ...
}:

{
  options.kompis-os-hm.fonts = {
    enable = lib.mkEnableOption "fonts";
  };

  config = lib.mkIf config.kompis-os-hm.fonts.enable {
    home.packages = [
      pkgs.hackgen-nf-font
    ]
    ++ lib.mapAttrsToList (name: font: pkgs.${font.package}) org.theme.fonts;

    fonts.fontconfig.enable = true;
    fonts.fontconfig.defaultFonts = lib.mapAttrs (name: font: [ font.name ]) org.theme.fonts;
  };
}
