# roles/nixos.nix
{
  flake.nixosModules.nixos =
    {
      host,
      ...
    }:
    {
      imports = [
        ../hosts/${host.name}/configuration.nix
        ../modules/system.nix
      ];
    };
}
