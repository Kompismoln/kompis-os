# flake.nix
{
  description = "o11n nixos fleet manager";

  inputs = {
    nixpkgs.url = "github:kompismoln/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver.url = "gitlab:ahbk/nixos-mailserver/relay-26.05";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    preservation.url = "github:nix-community/preservation";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake
      {
        inherit inputs;
      }
      (
        { lib, ... }:
        let
          o11nLib = import ./lib {
            inherit lib;
            o11nInputs = inputs;
          };
        in
        {
          systems = [ "x86_64-linux" ];
          imports = [ ./outputs.nix ];
          _module.args.o11nLib = o11nLib;

          perSystem =
            {
              pkgs,
              ...
            }:
            {
              checks = {
                unit-tests =
                  let
                    testResults = import ./tests { inherit pkgs o11nLib; };
                  in
                  if testResults == [ ] then
                    pkgs.emptyFile
                  else
                    pkgs.runCommand "test-results"
                      {
                        buildInputs = [ pkgs.jq ];
                        results = builtins.toJSON testResults;
                      }
                      ''
                        echo "$results" | jq .
                        exit 1
                      '';
              };
              devShells.default = pkgs.mkShell {
                buildInputs = [ ];
                shellHook = "";
              };
            };
        }
      );
}
