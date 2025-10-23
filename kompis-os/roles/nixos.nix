# roles/nixos.nix
{
  flake.nixosModules.nixos =
    {
      host,
      ...
    }:
    {
      imports = [
        ../../hosts/${host.name}/configuration.nix
        ../nixos/system.nix
      ];
    };
}
