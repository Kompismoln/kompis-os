# outputs.nix
{
  inputs,
  self,
  lib,
  ...
}:
let
  importDir = dir: (lib.mapAttrsToList (name: _: ./${dir}/${name}) (builtins.readDir ./${dir}));
in
{
  imports = [
    inputs.home-manager.flakeModules.home-manager
  ]
  ++ (importDir "roles");

  flake.mkOutputs =
    orgToml:
    let
      org =
        (lib.evalModules {
          modules = [
            ./org/default.nix
            { flake.org = lib.importTOML orgToml; }
          ];
          specialArgs = { inherit inputs; };
        }).config.flake.org;
    in
    {

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
        ) (lib.attrValues org.host)
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
                    (import ./overlays/tools.nix)
                  ];
                };
                extraSpecialArgs = {
                  inherit
                    home
                    inputs
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
