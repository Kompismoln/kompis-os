# kompis-os/outputs.nix
{
  inputs,
  self,
  lib,
  ...
}:
let
  lib' = (import ./lib) lib inputs;
  importDir = dir: (lib.mapAttrsToList (name: _: ./${dir}/${name}) (builtins.readDir ./${dir}));
in
{
  imports = [
    ./org.nix
    inputs.home-manager.flakeModules.home-manager
    lib'.diskoFlakeModule
  ]
  ++ (importDir "roles")
  ++ (importDir "disk-layouts");

  flake.org = inputs.org;

  flake.diskoConfigurations = lib.foldlAttrs (
    acc: host: hostCfg:
    acc
    // (lib.mapAttrs' (
      disk: diskCfg: lib.nameValuePair "${host}-${disk}" (self.diskoModules.${disk} { host = hostCfg; })
    ) hostCfg.disk-layouts)
  ) { } self.org.host;

  flake.homeConfigurations = lib.mapAttrs (
    home: homeCfg:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = inputs.nixpkgs.legacyPackages.${homeCfg.system};
      extraSpecialArgs = {
        home = homeCfg;
        org = self.org;
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
        org = self.org;
        inherit inputs lib';
      };
      modules = map (role: self.nixosModules.${role}) (
        lib.unique (
          hostCfg.roles
          ++ (lib.mapAttrsToList (layout: _: "disk-layout-${layout}") hostCfg.disk-layouts)
          ++ (lib.concatLists (lib.mapAttrsToList (_: userCfg: userCfg.roles) hostCfg.homes))
        )
      );
    }
  ) (lib.filterAttrs (_: cfg: lib.elem "nixos" cfg.roles) self.org.host);
}
