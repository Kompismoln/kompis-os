# roles/comfy-root.nix
_: {

  flake.nixosModules.comfy-root = {
    imports = [
      ../nixos/shell.nix
    ];

    config = {
      kompis-os = {
        shell.enable = true;
      };
    };
  };
}
