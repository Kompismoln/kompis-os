# kompis-os/roles/substituter.nix
{
  flake.nixosModules.substituter = {
    imports = [
      ../nixos/org/nix-serve.nix
    ];
  };
}
