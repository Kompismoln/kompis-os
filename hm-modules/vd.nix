{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkEnableOption mkIf;

  cfg = config.kompis-os-hm.vd;
in
{
  options.kompis-os-hm.vd = {
    enable = mkEnableOption "Enable visual design tools for this user";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      inkscape
      figma-linux
      krita
    ];
  };
}
