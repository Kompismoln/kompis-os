# roles/cli-devstation.nix
{
  flake.homeModules.cli-devstation = {
    imports = [
      ../home/org/home.nix
      ../home/org/ide.nix
      ../home/org/nix-conf.nix
      ../home/org/shell.nix
      ../home/org/xdg.nix
    ];
  };

  flake.nixosModules.cli-devstation = {
    imports = [
      ../nixos/org/home-manager.nix
      ../nixos/org/shell.nix
    ];
  };
}
