{
  config,
  lib,
  ...
}:
{
  options.kompis-os-hm.xdg = {
    enable = lib.mkEnableOption "xdg base directories";
  };

  config = lib.mkIf config.kompis-os-hm.xdg.enable {
    xdg.enable = true;
    home.sessionVariables.XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
    home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
    nix.settings.use-xdg-base-directories = true;
  };
}
