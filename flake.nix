{
  description = "my nixos";

  inputs = {
    nixpkgs.url = "github:kompismoln/nixpkgs/nixos-unstable";

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

    sverigesval-sync.url = "git+ssh://git@github.com/ahbk/sverigesval.org";
    sverigesval-sync.inputs.nixpkgs.follows = "nixpkgs";

    chatddx.url = "git+ssh://git@github.com/LigninDDX/chatddx";
    chatddx.inputs.nixpkgs.follows = "nixpkgs";

    kompismoln-site.url = "git+ssh://git@github.com/Kompismoln/website";
    kompismoln-site.inputs.nixpkgs.follows = "nixpkgs";

    klimatkalendern.url = "github:Kompismoln/klimatkalendern";
    klimatkalendern.inputs.nixpkgs.follows = "nixpkgs";

    klimatkalendern-dev.url = "github:Kompismoln/klimatkalendern/dev";
    klimatkalendern-dev.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, home-manager, ... }@inputs:
    let
      inherit (nixpkgs) lib;
      inherit (home-manager.lib) homeManagerConfiguration;
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      lib' = (import ./lib) nixpkgs.lib;

      org-unwrapped = builtins.fromTOML (builtins.readFile ./org.toml);
      org = lib.recursiveUpdate org-unwrapped {
        theme.colors = lib'.semantic-colors org-unwrapped.theme.colors;
      };

    in
    {
      homeConfigurations = lib.mapAttrs (
        homeManagerName: homeManagerCfg:
        homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.${homeManagerCfg.system};
          extraSpecialArgs =
            let
              userhost = lib.splitString "@" homeManagerName;
              username = builtins.elemAt userhost 0;
              hostname = builtins.elemAt userhost 1;
            in
            {
              hmHost = homeManagerCfg // {
                inherit username hostname;
              };
              inherit inputs org lib';
            };
          modules = map (role: ./home-manager/roles/${role}.nix) homeManagerCfg.roles;
        }
      ) org.home-manager;

      nixosConfigurations = lib.mapAttrs (
        hostname: hostCfg:
        lib.nixosSystem {
          specialArgs = {
            host = hostCfg // {
              name = hostname;
            };
            inherit inputs org lib';
          };
          modules = map (role: ./roles/${role}.nix) hostCfg.roles;
        }
      ) (lib.filterAttrs (_: cfg: lib.elem "nixos" cfg.roles) org.host);

      devShells.${system}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          toml2json
        ];
        shellHook = ''
          export SOPS_AGE_KEY_FILE=/keys/root-1
          export BUILD_HOST=./
          PATH=$(pwd)/tools/bin:$PATH
        '';
      };

    };
}
