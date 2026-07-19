# roles/comfy-root.nix
_: {

  flake.nixosModules.comfy-root = {
    imports = [
      ../nixos/shell.nix
    ];

    config = {
      o11n = {
        shell.enable = true;
      };
    };
  };
}
