# kompis-os/nixos/home-manager.nix
{
  config,
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

  options.kompis-os.home-manager = {
    enable = lib.mkEnableOption "home-manager";
  };

  config = lib.mkIf config.kompis-os.home-manager.enable {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs lib' org;
      };
      users = lib.mapAttrs (username: homeCfg: {
        _module.args.home = lib'.home-args username host.name;
        home.packages = [ pkgs.home-manager ];

        imports = map (role: inputs.self.homeModules.${role}) homeCfg.roles;

      }) org.host.${host.name}.home;
    };
  };
}
