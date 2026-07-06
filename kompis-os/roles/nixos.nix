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
        ../nixos/system.nix
        ../nixos/paths.nix
        ../nixos/org.nix
      ];
    };
}
