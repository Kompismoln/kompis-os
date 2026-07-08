# kompis-os/outputs.nix
{
  inputs,
  self,
  lib,
  ...
}:
let
  lib' = (import ./lib) lib inputs self.org;
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

  _module.args.lib' = lib';

  flake = {
    inherit (inputs) org;

    diskoConfigurations = lib.foldlAttrs (
      acc: host:
      acc
      // (lib.mapAttrs' (
        disk: lib.nameValuePair "${host.name}-${disk.name}" (self.diskoModules.${disk.module} disk)
      ) (lib.attrValues host.disk))
    ) { } (lib.attrValues self.org.host);

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
            }) (hostCfg.home or { })
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
          (lib.optionals (hostCfg.disk != { }) [ nixos/disko.nix ])
          ++ map (role: self.nixosModules.${role}) (
            lib.unique (
              hostCfg.roles
              ++ (lib.mapAttrsToList (_: diskCfg: "disk-layout-${diskCfg.module}") hostCfg.disk)
              ++ (lib.concatLists (lib.mapAttrsToList (_: userCfg: userCfg.roles) hostCfg.home))
            )
          );
      }
    ) (lib.filterAttrs (_: cfg: lib.elem "nixos" cfg.roles) self.org.host);
  };
}
