# roles/nixos.nix
{
  flake.nixosModules.nixos =
    {
      host,
      ...
    }:
    {
      imports = [
        host.configurationFile
        ../nixos/org/boot.nix
        ../nixos/org/system.nix
        ../nixos/org/principals.nix
      ];
    };
}
