# kompis-os/roles/workstation.nix
{ inputs, ... }:
{
  flake.homeModules.workstation =
    { org, home, ... }:
    {
      imports = [
        inputs.nixvim.homeModules.nixvim
        ../home/desktop-env.nix
        ../home/ide.nix
        ../home/shell.nix
        ../home/user.nix
        ../home/vd.nix
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
    config = {
      nixpkgs.overlays = [
        (import ../overlays/workstation.nix { inherit inputs; })
      ];
      home-manager.sharedModules = [
        inputs.nixvim.homeModules.nixvim
        ../home/desktop-env.nix
        ../home/ide.nix
        ../home/shell.nix
        ../home/user.nix
        ../home/vd.nix
      ];
    };
    imports = [
      ../nixos/desktop-env.nix
      ../nixos/home-manager.nix
      ../nixos/ide.nix
      ../nixos/mysql.nix
      ../nixos/postgresql.nix
      ../nixos/shell.nix
      ../nixos/vd.nix
    ];
  };
}
