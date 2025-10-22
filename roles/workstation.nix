# roles/workstation.nix
{ inputs, ... }:
{
  flake.homeModules.workstation =
    { org, home, ... }:
    {
      imports = [
        inputs.nixvim.homeModules.nixvim
        ../home-manager/desktop-env.nix
        ../home-manager/ide.nix
        ../home-manager/shell.nix
        ../home-manager/user.nix
        ../home-manager/vd.nix
      ];
      kompis-os-hm = {
        ide = {
          enable = true;
          name = org.user.${home.username}.description;
          email = org.user.${home.username}.email;
        };
        shell.enable = true;
        user = {
          enable = true;
          name = home.username;
        };
      };
    };

  flake.nixosModules.workstation = {
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
  };
}
