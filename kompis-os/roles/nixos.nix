# kompis-os/roles/nixos.nix
{
  flake.nixosModules.nixos =
    {
      host,
      ...
    }:
    {
      imports = [
        host.configurationFile
        ../nixos/org/system.nix
      ];
    };
}
