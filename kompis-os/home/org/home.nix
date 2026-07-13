# kompis-os/home/home.nix
{
  home,
  lib,
  ...
}:
{
  programs.home-manager.enable = true;

  home = {
    inherit (home) stateVersion username;
    homeDirectory = lib.mkDefault /home/${home.username};
  };
}
