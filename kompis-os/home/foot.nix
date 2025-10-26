{
  config,
  lib,
  lib',
  org,
  ...
}:

let
  inherit (org.theme) fonts;
  colors = lib'.semantic-colors org.theme.colors;
  unhashedHexes = lib.mapAttrs (n: c: lib.substring 1 6 c) colors;
  cfg = config.kompis-os-hm.foot;
in

{
  options.kompis-os-hm.foot = {
    enable = lib.mkEnableOption "foot terminal";
  };

  config = lib.mkIf cfg.enable {
    programs.foot = {
      enable = true;
      settings = {
        main.font = "${fonts.monospace.name}:size=11";
        main.dpi-aware = "no";
        mouse.hide-when-typing = "yes";
        colors = with unhashedHexes; {
          alpha = 0.8;
          background = bg-300;
          foreground = fg-200;

          regular0 = base00;
          regular1 = base01;
          regular2 = base02;
          regular3 = base03;
          regular4 = base04;
          regular5 = base05;
          regular6 = base06;
          regular7 = base07;

          bright0 = base08;
          bright1 = base09;
          bright2 = base0A;
          bright3 = base0B;
          bright4 = base0C;
          bright5 = base0D;
          bright6 = base0E;
          bright7 = base0F;
        };
      };
    };
  };
}
