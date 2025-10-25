{
  config,
  pkgs,
  lib,
  ...
}:
{
  options.kompis-os-hm.graphic = {
    enable = lib.mkEnableOption "graphic tools";
  };

  config = lib.mkIf config.kompis-os-hm.graphic.enable {
    home.packages = with pkgs; [
      inkscape
      krita
      aileron
      barlow
      cabin
      dm-sans
      fira
      fira-code
      fira-code-symbols
      font-awesome
      garamond-libre
      # helvetica-neue-lt-std
      ibm-plex
      inter
      jost
      kanit-font
      libre-baskerville
      libre-bodoni
      libre-franklin
      liberation_ttf
      manrope
      mplus-outline-fonts.githubRelease
      montserrat
      noto-fonts
      noto-fonts-emoji
      oxygenfonts
      roboto
      roboto-mono
      roboto-slab
      roboto-serif
      paratype-pt-sans
      proggyfonts
      raleway
      redhat-official-fonts
      rubik
      source-sans-pro
      ubuntu_font_family
    ];
  };
}
