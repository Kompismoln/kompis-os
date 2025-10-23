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
      extraSpecialArgs =
        let
          userhost = lib.splitString "@" home;
          username = builtins.elemAt userhost 0;
          hostname = builtins.elemAt userhost 1;
        in
        {
          home = homeCfg // {
            inherit username hostname;
          };
          org = inputs.org;
          inherit lib';
        };
      modules = map (role: self.homeModules.${role}) homeCfg.roles;
    }
  ) inputs.org.home-manager;

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
