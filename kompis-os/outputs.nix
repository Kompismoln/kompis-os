# kompis-os/outputs.nix
{
  inputs,
  self,
  lib,
  ...
}:
let
  inherit (self) org;
  lib' = (import ./lib) lib inputs org;
  importDir = dir: (lib.mapAttrsToList (name: _: ./${dir}/${name}) (builtins.readDir ./${dir}));
in
{
  imports = [
    ./org.nix
    inputs.home-manager.flakeModules.home-manager
  ]
  ++ (importDir "roles");

  _module.args.lib' = lib';

  flake = {

    diskoConfigurations = lib.listToAttrs (
      lib.concatMap (
        host:
        (map (
          disk:
          lib.nameValuePair "${host.name}-${disk.name}" (
            (import ./disk-layouts/${disk.layout}.nix) {
              inherit
                host
                disk
                lib
                org
                ;
              pkgs = inputs.nixpkgs.legacyPackages.${host.system};
            }
          )
        ) (lib.attrValues host.disk-layouts))
      ) (lib.attrValues self.org.host)
    );

    homeConfigurations = lib.listToAttrs (
      lib.concatMap (
        host:
        (map (
          home:
          lib.nameValuePair home.name (
            inputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import inputs.nixpkgs {
                inherit (host) system;
                overlays = [
                  ((import ./overlays/tools.nix) { inherit (inputs.self) outPath; })
                ];
              };
              extraSpecialArgs = {
                inherit
                  home
                  inputs
                  lib'
                  org
                  ;
              };
              modules = [
                home.configurationFile
              ]
              ++ map (role: self.homeModules.${role}) home.roles;
            }
          )
        ) (lib.attrValues host.home))
      ) (lib.attrValues org.host)
    );

    nixosConfigurations = lib.listToAttrs (
      map (
        host:
        lib.nameValuePair host.name (
          inputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit
                host
                inputs
                lib'
                org
                ;
            };
            modules =
              (lib.optionals (host.disk-layouts != { }) [ nixos/disko.nix ])
              ++ map (role: self.nixosModules.${role}) (
                lib.unique (host.roles ++ (lib.concatMap (home: home.roles) (lib.attrValues host.home)))
              );
          }
        )
      ) (lib.filter (host: lib.elem "nixos" host.roles) (lib.attrValues org.host))
    );
  };
}
