# kompis-os/home/home.nix
{
  config,
  home,
  lib,
  ...
}:
{
  options.kompis-os-hm.home = {
    enable = lib.mkEnableOption "home-manager essentials";
  };

  config = lib.mkIf config.kompis-os-hm.home.enable {

    programs.home-manager.enable = true;

    home = {
      inherit (home) stateVersion username;
      homeDirectory = lib.mkDefault /home/${home.username};
    };
  };
}
