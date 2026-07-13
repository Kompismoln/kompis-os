# kompis-os/roles/hypr-mediastation.nix
{
  flake.homeModules.hypr-mediastation = {
    imports = [
      ../home/org/home.nix
      ../home/org/hyprland.nix
      ../home/org/nix-conf.nix
      ../home/org/qutebrowser.nix
      ../home/org/shell.nix
      ../home/org/xdg.nix
    ];
  };

  flake.nixosModules.hypr-mediastation =
    { pkgs, ... }:
    {
      imports = [
        ../nixos/org/home-manager.nix
        ../nixos/org/hyprland.nix
        ../nixos/org/shell.nix
        ../nixos/org/sound.nix
      ];

      config = {
        services = {
          transmission = {
            enable = true;
            package = pkgs.transmission_4-qt;
          };
        };
      };
    };
}
