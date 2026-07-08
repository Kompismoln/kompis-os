{ outPath }:

final: _: {
  km-tools = final.callPackage ../packages/km-tools.nix { inherit outPath; };
  origin = final.callPackage ../packages/origin.nix { };
}
