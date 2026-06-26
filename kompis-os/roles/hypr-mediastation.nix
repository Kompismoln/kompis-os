# kompis-os/roles/hypr-mediastation.nix
{
  flake.homeModules.hypr-mediastation = {
    imports = [
      ../home/home.nix
      ../home/hyprland.nix
      ../home/nix-conf.nix
      ../home/qutebrowser.nix
      ../home/shell.nix
      ../home/xdg.nix
    ];
    config = {
      kompis-os-hm = {
        home.enable = true;
        hyprland = {
          enable = true;
          hyprlock = false;
        };
        nix-conf.enable = true;
        qutebrowser.enable = true;
        shell.enable = true;
        xdg.enable = true;
      };
    };
  };

  flake.nixosModules.hypr-mediastation =
    { pkgs, ... }:
    {
      imports = [
        ../nixos/home-manager.nix
        ../nixos/hyprland.nix
        ../nixos/shell.nix
        ../nixos/sound.nix
      ];

      config = {
        services = {
          transmission = {
            enable = true;
            package = pkgs.transmission_4-qt;
          };
        };

        kompis-os = {
          home-manager.enable = true;
          hyprland.enable = true;
          shell.enable = true;
          sound.enable = true;
        };
      };
    };
}
