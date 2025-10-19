{ inputs, ... }:
{
  imports = [
    ../modules/desktop-env.nix
    ../modules/home-manager.nix
    ../modules/ide.nix
    ../modules/mysql.nix
    ../modules/postgresql.nix
    ../modules/shell.nix
    ../modules/vd.nix
  ];
  nixpkgs.overlays = [
    (import ../overlays/workstation.nix { inherit inputs; })
  ];
}
