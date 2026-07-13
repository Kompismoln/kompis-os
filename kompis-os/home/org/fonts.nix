{
  lib,
  org,
  pkgs,
  ...
}:

{
  home.packages = [
    pkgs.hackgen-nf-font
  ]
  ++ map (font: pkgs.${font.package}) (lib.attrValues org.theme.fonts);

  fonts.fontconfig.enable = true;
  fonts.fontconfig.defaultFonts = lib.mapAttrs (_: font: [ font.name ]) org.theme.fonts;
}
