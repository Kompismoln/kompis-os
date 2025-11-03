# kompis-os/roles/nixos.nix
{
  flake.nixosModules.nixos =
    {
      host,
      lib',
      ...
    }:
    {
      imports = [
        "${lib'.host-config host.name}"
        ../nixos/system.nix
        ../nixos/paths.nix
        ../nixos/org.nix
      ];
    };
}
