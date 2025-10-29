{ inputs }:

final: prev: {
  pgsql-restore = final.callPackage ../packages/pgsql-restore.nix { inherit inputs; };
  pgsql-dump = final.callPackage ../packages/pgsql-dump.nix { inherit inputs; };
  pgsql-init = final.callPackage ../packages/pgsql-init.nix { inherit inputs; };
}
