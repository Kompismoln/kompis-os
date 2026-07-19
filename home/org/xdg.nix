{
  config,
  ...
}:
{
  xdg.enable = true;
  home.sessionVariables.XDG_BIN_HOME = "${config.home.homeDirectory}/.local/bin";
  home.sessionPath = [ "${config.home.homeDirectory}/.local/bin" ];
  nix.settings.use-xdg-base-directories = true;
}
