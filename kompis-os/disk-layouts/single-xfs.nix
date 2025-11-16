# kompis-os/roles/single-xfs.nix
{
  inputs,
  lib,
  self,
  ...
}:
let
  name = "single-xfs";
in
{
  flake.nixosModules.${name} =
    { host, ... }:
    {
      imports = [
        inputs.disko.nixosModules.disko
      ];

      disko = (self.diskoConfigurations.${host.name}).disko;
    };

  flake.diskoConfigurations = lib.mapAttrs (host: hostCfg: {
    disko.devices = {
      disk = {
        type = "disk";
        device = hostCfg.${name}.device;
        content = {
          type = "gpt";
          partitions = {
            raid = {
              size = "100%";
              content = {
                type = "mdraid";
                name = "raid1";
              };
            };
          };
        };
      };
    };
  }) (lib.filterAttrs (host: hostCfg: lib.elem name hostCfg.roles) inputs.org.host);
}
