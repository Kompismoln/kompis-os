# kompis-os/nixos/disko.nix
{
  lib,
  host,
  inputs,
  ...
}:
{
  imports = [
    inputs.disko.nixosModules.disko
    ../nixos/preserve.nix
  ];

  config = lib.mkIf (host.disk-layouts != { }) {

    environment.systemPackages = [
      inputs.disko.packages.${host.system}.default
    ];

    kompis-os.disk-layouts = lib.foldlAttrs (
      acc: disk: diskCfg:
      let
        name = diskCfg.module;
        value = builtins.removeAttrs diskCfg [ "module" ];
      in
      acc
      // {
        ${name} = (acc.${name} or { }) // {
          ${disk} = value;
        };
      }
    ) { } host.disk-layouts;
  };
}
