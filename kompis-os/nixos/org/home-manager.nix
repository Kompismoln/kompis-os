# nixos/org/home-manager.nix
{
  host,
  inputs,
  lib,
  lib',
  org,
  pkgs,
  ...
}:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs lib' org;
    };
    users = lib.mapAttrs (_: home: {
      _module.args.home = home;

      home.packages = [ pkgs.home-manager ];

      imports = [
        home.configurationFile
      ]
      ++ map (role: inputs.self.homeModules.${role}) home.roles;
    }) org.host.${host.name}.home;
  };
}
