# nixos/disko.nix
{
  config,
  host,
  lib,
  o11nInputs,
  diskoConfigurations,
  ...
}:
{
  imports = [
    o11nInputs.disko.nixosModules.disko
    ../nixos/preserve.nix
  ];

  config = lib.mkMerge (
    (map (disk: diskoConfigurations."${host.name}-${disk.name}") (lib.attrValues host.disk-layouts))
    ++ [
      (lib.mkIf (host.disk-layouts != { }) {
        sops.secrets.luks-key = { };

        boot.initrd.secrets."${host.luksKeyFile}" = config.sops.secrets.luks-key.path;
      })
    ]
  );

}
