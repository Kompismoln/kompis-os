# outputs.nix
{
  inputs,
  lib,
  o11nLib,
  ...
}:
let
  importDir = dir: (lib.mapAttrsToList (name: _: /${dir}/${name}) (builtins.readDir dir));
  o11nInputs = inputs;
in
{
  imports = [
    o11nInputs.home-manager.flakeModules.home-manager
  ]
  ++ (importDir ./roles);

  flake = {
    fromPath =
      path:
      let
        orgFlake = o11nLib.mkOrgFlake { inherit path; };
        inherit (orgFlake) inputs org;
      in
      o11nLib.mkConfigurations inputs org;

    fromFlake =
      flake:
      let
        orgFlake = o11nLib.mkOrgFlake {
          inherit flake;
          path = flake.outPath;
        };
        inherit (orgFlake) inputs org;
      in
      o11nLib.mkConfigurations inputs org;

    nixosModules = {
      django = nixos/django.nix;
      nginx = nixos/nginx.nix;
      postgresql = nixos/postgresql.nix;
      collabora = nixos/collabora.nix;
      nextcloud = nixos/nextcloud.nix;
      redis = nixos/redis.nix;
      mysql = nixos/mysql.nix;
      wordpress = nixos/wordpress.nix;
      mobilizon = nixos/mobilizon.nix;
      nextcloud-rolf = nixos/nextcloud-rolf.nix;
    };
  };
}
