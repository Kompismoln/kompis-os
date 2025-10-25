{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kompis-os-hm.browsers = {
    enable = lib.mkEnableOption "browsers";
  };

  config = lib.mkIf config.kompis-os-hm.browsers.enable {
    home.packages = with pkgs; [
      chromium
      firefox
      nyxt
    ];
  };
}
