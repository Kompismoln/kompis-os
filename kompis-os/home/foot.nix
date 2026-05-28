{
  config,
  lib,
  ...
}:

let
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
        security.osc52 = "copy-enabled";
        main.dpi-aware = "no";
        mouse.hide-when-typing = "yes";
      };
    };
  };
}
