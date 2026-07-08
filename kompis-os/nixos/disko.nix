# kompis-os/nixos/disko.nix
{
  lib,
  host,
  inputs,
  config,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ../nixos/preserve.nix
  ];

  config = lib.mkIf (host.disk != { }) {

    environment.systemPackages = [
      inputs.disko.packages.${host.system}.default
    ];
    sops.secrets.luks-key = { };
    boot.initrd.secrets."${host.luksKeyFile}" = config.sops.secrets.luks-key.path;

  };
}
