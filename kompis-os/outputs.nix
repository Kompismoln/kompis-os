# kompis-os/outputs.nix
{
  inputs,
  self,
  lib,
  ...
}:
let
  lib' = (import ./lib) lib inputs;
in
{
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ]
  ++ (lib.mapAttrsToList (name: _: ./roles/${name}) (builtins.readDir ./roles));

  flake.homeConfigurations = lib.mapAttrs (
    home: homeCfg:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${homeCfg.system};
      extraSpecialArgs = {
        home = homeCfg;
        org = inputs.org;
        inherit inputs lib';
      };
      modules = [
        homeCfg.configPath
      ]
      ++ map (role: self.homeModules.${role}) homeCfg.roles;
    }
  ) lib'.homes;

  flake.nixosConfigurations = lib.mapAttrs (
    host: hostCfg:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        host = hostCfg // {
          name = host;
        };
        org = inputs.org;
        inherit inputs lib';
      };
      modules = map (role: self.nixosModules.${role}) hostCfg.roles;
    }
  ) (lib.filterAttrs (_: cfg: lib.elem "nixos" cfg.roles) inputs.org.host);
}
