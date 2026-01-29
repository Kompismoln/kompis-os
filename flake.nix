# flake.nix
{
  description = "Kompismoln";

  inputs = {
    nixpkgs.url = "github:kompismoln/nixpkgs/nixos-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs";

    nixos-mailserver.url = "gitlab:ahbk/nixos-mailserver/relay";
    nixos-mailserver.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    preservation.url = "github:nix-community/preservation";

    nixos-cli.url = "github:nix-community/nixos-cli";
    nixos-cli.inputs.nixpkgs.follows = "nixpkgs";

    sverigesval.url = "git+ssh://git@github.com/ahbk/sverigesval.org";
    sverigesval.inputs.nixpkgs.follows = "nixpkgs";

    sverigesval-dev.url = "git+ssh://git@github.com/ahbk/sverigesval.org";
    sverigesval-dev.inputs.nixpkgs.follows = "nixpkgs";

    chatddx.url = "git+ssh://git@github.com/LigninDDX/chatddx";
    chatddx.inputs.nixpkgs.follows = "nixpkgs";

    chatddx-dev.url = "git+ssh://git@github.com/LigninDDX/chatddx";
    chatddx-dev.inputs.nixpkgs.follows = "nixpkgs";

    kompismoln-site.url = "github:Kompismoln/site";
    kompismoln-site.inputs.nixpkgs.follows = "nixpkgs";

    klimatkalendern.url = "github:Kompismoln/klimatkalendern";
    klimatkalendern.inputs.nixpkgs.follows = "nixpkgs";

    klimatkalendern-dev.url = "github:Kompismoln/klimatkalendern/dev";
    klimatkalendern-dev.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake
      {
        inputs = inputs // {
          org = fromTOML (builtins.readFile ./org.toml);
        };
      }
      {
        systems = [ "x86_64-linux" ];
        imports = [ ./kompis-os/outputs.nix ];
        flake = {
          src = inputs.self.outPath;
        };
        perSystem =
          { pkgs, ... }:
          {
            devShells.default = pkgs.mkShell {
              buildInputs = with pkgs; [
                toml2json
              ];
              shellHook = ''
                export SOPS_AGE_KEY_FILE=/keys/root-1
                export BUILD_HOST=pelle
                export BUILD_WORKING_TREE=true
                export RESTIC_REPOSITORY="$HOME/.restic"
                export RESTIC_PASSWORD_FILE="/run/secrets/alex/restic-key"
                PATH=$(pwd)/kompis-os/tools/bin:$PATH
              '';
            };
          };
      };
}
