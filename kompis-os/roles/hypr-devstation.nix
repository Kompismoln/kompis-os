# kompis-os/roles/hypr-devstation.nix
{ inputs, ... }:
{
  flake.homeModules.hypr-devstation = {
    imports = [
      ../home/browsers.nix
      ../home/fonts.nix
      ../home/graphic.nix
      ../home/home.nix
      ../home/hyprland.nix
      ../home/ide.nix
      ../home/nix-conf.nix
      ../home/qutebrowser.nix
      ../home/shell.nix
      ../home/social.nix
      ../home/xdg.nix
    ];
    config = {
      kompis-os-hm = {
        browsers.enable = true;
        fonts.enable = true;
        graphic.enable = true;
        home.enable = true;
        hyprland.enable = true;
        ide.enable = true;
        nix-conf.enable = true;
        qutebrowser.enable = true;
        shell.enable = true;
        social.enable = true;
        xdg.enable = true;
      };
    };
  };

  flake.nixosModules.hypr-devstation = {
    imports = [
      ../nixos/home-manager.nix
      ../nixos/hyprland.nix
      ../nixos/ide.nix
      ../nixos/networkmanager.nix
      ../nixos/shell.nix
      ../nixos/sound.nix
    ];

    config = {
      kompis-os = {
        home-manager.enable = true;
        hyprland.enable = true;
        ide.enable = true;
        networkmanager.enable = true;
        shell.enable = true;
        sound.enable = true;
      };

      nixpkgs.overlays = [
        (import ../overlays/km-tools.nix { inherit inputs; })
      ];

    };
  };
}
