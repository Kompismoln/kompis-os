# kompis-os/roles/cinnamon-office.nix
{
  flake.homeModules.cinnamon-office = {
    imports = [
      ../home/home.nix
      ../home/nix-conf.nix
      ../home/office.nix
      ../home/social.nix
      ../home/xdg.nix
    ];
    config = {
      kompis-os-hm = {
        home.enable = true;
        nix-conf.enable = true;
        office.enable = true;
        social.enable = true;
        xdg.enable = true;
      };
    };
  };

  flake.nixosModules.cinnamon-office =
    { lib, ... }:
    {
      imports = [
        ../nixos/cinnamon.nix
        ../nixos/home-manager.nix
        ../nixos/networkmanager.nix
        ../nixos/sound.nix
      ];

      config = {
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "zoom"
          ];
        kompis-os = {
          cinnamon.enable = true;
          home-manager.enable = true;
          networkmanager.enable = true;
          sound.enable = true;
        };
      };
    };
}
