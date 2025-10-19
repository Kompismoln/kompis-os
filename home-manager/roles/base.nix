{
  hmHost,
  inputs,
  ...
}:
{
  imports = [
    inputs.nixvim.homeModules.nixvim
    ../desktop-env.nix
    ../ide.nix
    ../shell.nix
    ../user.nix
    ../vd.nix
  ];
  home.stateVersion = hmHost.stateVersion;
  home.username = hmHost.username;
  home.homeDirectory = /home/${hmHost.username};
}
