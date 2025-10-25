# kompis-os/roles/workstation.nix
{ inputs, ... }:
{
  flake.homeModules.workstation = {
    imports = [
      ../home/ide.nix
      ../home/fonts.nix
    ];
  };

  flake.nixosModules.workstation = {
    imports = [
      ../nixos/shell.nix
      ../nixos/ide.nix
    ];

    config = {
    };
  };
}
