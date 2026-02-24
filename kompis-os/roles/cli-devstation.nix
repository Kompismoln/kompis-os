# kompis-os/roles/cli-devstation.nix
{ inputs, ... }:
{
  flake.homeModules.cli-devstation = {
    imports = [
      ../home/home.nix
      ../home/ide.nix
      ../home/nix-conf.nix
      ../home/shell.nix
      ../home/xdg.nix
    ];
    config = {
      kompis-os-hm = {
        home.enable = true;
        ide.enable = true;
        nix-conf.enable = true;
        shell.enable = true;
        xdg.enable = true;
      };
    };
  };

  flake.nixosModules.cli-devstation = {
    imports = [
      ../nixos/home-manager.nix
      ../nixos/shell.nix
    ];

    config = {
      kompis-os = {
        home-manager.enable = true;
        shell.enable = true;
        tls-certs = inputs.org.namespaces;
      };
    };
  };
}
