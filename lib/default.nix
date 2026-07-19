# lib/default.nix
{
  lib,
  o11nInputs,
}:
rec {
  fromPath =
    path:
    let
      orgFlake = mkOrgFlake { inherit path; };
      inherit (orgFlake) inputs org;
    in
    mkConfigurations inputs org;

  fromFlake =
    flake:
    let
      orgFlake = mkOrgFlake {
        inherit flake;
        path = flake.outPath;
      };
      inherit (orgFlake) inputs org;
    in
    mkConfigurations inputs org;

  mkOrgFlake =
    config:
    let
      module = lib.evalModules {
        modules = [
          ../org
          config
        ];
      };
    in
    module.config;

  mkConfigurations = inputs: org: {
    inherit org;

    diskoConfigurations = mkDiskoConfigurations inputs org;

    homeConfigurations = mkHomeConfigurations inputs org;

    nixosConfigurations = mkNixosConfigurations inputs org;
  };

  mkNixosConfigurations =
    inputs: org:
    lib.listToAttrs (
      map (
        host:
        lib.nameValuePair host.name (
          o11nInputs.nixpkgs.lib.nixosSystem {
            specialArgs = {
              inherit
                host
                inputs
                o11nInputs
                org
                ;
              diskoConfigurations = lib.filterAttrs (name: _: lib.hasPrefix "${host.name}-" name) (
                mkDiskoConfigurations inputs org
              );
            };
            modules =
              (lib.optionals (host.disk-layouts != { }) [ ../nixos/disko.nix ])
              ++ map (role: o11nInputs.self.nixosModules.${role}) (
                lib.unique (host.roles ++ (lib.concatMap (home: home.roles) (lib.attrValues host.home)))
              );
          }
        )
      ) (lib.filter (host: lib.elem "nixos" host.roles) (lib.attrValues org.host))
    );

  mkHomeConfigurations =
    inputs: org:
    lib.listToAttrs (
      lib.concatMap (
        host:
        (map (
          home:
          lib.nameValuePair home.name (
            o11nInputs.home-manager.lib.homeManagerConfiguration {
              pkgs = import o11nInputs.nixpkgs {
                inherit (host) system;
                overlays = [
                  (import ../overlays/tools.nix)
                ];
              };
              extraSpecialArgs = {
                inherit
                  home
                  inputs
                  o11nInputs
                  org
                  ;
              };
              modules = [
                home.configurationFile
              ]
              ++ map (role: o11nInputs.self.homeModules.${role}) home.roles;
            }
          )
        ) (lib.attrValues host.home))
      ) (lib.attrValues org.host)
    );

  mkDiskoConfigurations =
    _: org:
    lib.listToAttrs (
      lib.concatMap (
        host:
        (map (
          disk:
          lib.nameValuePair "${host.name}-${disk.name}" (

            (import ../disk-layouts/${disk.layout}.nix) {
              inherit
                host
                disk
                lib
                org
                ;
              pkgs = o11nInputs.nixpkgs.legacyPackages.${host.system};
            }
          )
        ) (lib.attrValues host.disk-layouts))
      ) (lib.attrValues org.host)
    );
}
