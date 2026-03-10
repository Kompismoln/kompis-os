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

  flake = {
    inherit (inputs) org;

    diskoConfigurations = lib.foldlAttrs (
      acc: host: hostCfg:
      acc
      // (lib.mapAttrs' (
        disk: diskCfg:
        lib.nameValuePair "${host}-${disk}" (self.diskoModules.${diskCfg.module} disk diskCfg)
      ) hostCfg.disk-layouts)
    ) { } self.org.host;

    homeConfigurations =
      lib.mapAttrs
        (
          _: homeCfg:
          inputs.home-manager.lib.homeManagerConfiguration {
            pkgs = import inputs.nixpkgs {
              inherit (homeCfg) system;
              overlays = [
                ((import ./overlays/tools.nix) { inherit inputs; })
              ];
            };
            extraSpecialArgs = {
              home = homeCfg;
              inherit (self) org;
              inherit inputs lib';
            };
            modules = [
              homeCfg.configPath
            ]
            ++ map (role: self.homeModules.${role}) homeCfg.roles;
          }
        )
        (
          lib.concatMapAttrs (
            host: hostCfg:
            lib.mapAttrs' (username: _: {
              name = "${username}@${host}";
              value = lib'.home-args username host;
            }) (hostCfg.homes or { })
          ) inputs.org.host
        );

    nixosConfigurations = lib.mapAttrs (
      host: hostCfg:
      inputs.nixpkgs.lib.nixosSystem {
        specialArgs = {
          host = hostCfg // {
            name = host;
          };
          inherit (self) org;
          inherit inputs lib';
        };
        modules =
          (lib.optionals (hostCfg.disk-layouts != { }) [ nixos/disko.nix ])
          ++ map (role: self.nixosModules.${role}) (
            lib.unique (
              hostCfg.roles
              ++ (lib.mapAttrsToList (_: diskCfg: "disk-layout-${diskCfg.module}") hostCfg.disk-layouts)
              ++ (lib.concatLists (lib.mapAttrsToList (_: userCfg: userCfg.roles) hostCfg.homes))
            )
          );
      }
    ) (lib.filterAttrs (_: cfg: lib.elem "nixos" cfg.roles) self.org.host);
  };
}
