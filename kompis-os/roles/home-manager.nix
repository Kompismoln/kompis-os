# kompis-os/roles/home-manager.nix
{
  flake.homeModules.home-manager =
    { home, ... }:
    {
      home.stateVersion = home.stateVersion;
      home.username = home.username;
      home.homeDirectory = /home/${home.username};
    };
}
