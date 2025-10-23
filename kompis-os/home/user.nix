{
  config,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    hm
    mkDefault
    mkEnableOption
    mkForce
    mkIf
    mkOption
    types
    ;

  cfg = config.kompis-os-hm.user;
in
{
  options.kompis-os-hm.user = {
    enable = mkEnableOption "home-manager for this user";
    uid = mkOption {
      description = "User id.";
      type = types.int;
    };
    name = mkOption {
      description = "Name for the user.";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    programs.home-manager.enable = true;
    nix = {
      package = mkForce pkgs.lix;
      settings = {
        auto-optimise-store = false;
        bash-prompt-prefix = "(nix:$name)\\040";
        experimental-features = [
          "nix-command"
          "flakes"
        ];
        extra-nix-path = "nixpkgs=flake:nixpkgs";
        max-jobs = "auto";
        substituters = [
          "https://cache.nixos.org"
          "https://cache.lix.systems"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "cache.lix.systems:aBnZUw8zA7H35Cz2RyKFVs3H4PlGTLawyY5KRbvJR8o="
        ];
        use-xdg-base-directories = true;
      };
    };
    home = {
      username = cfg.name;
      homeDirectory = mkDefault /home/${cfg.name};
      activation = {
        prune-home = hm.dag.entryAfter [ "writeBoundary" ] ''
          rm -rf /home/${cfg.name}/.nix-defexpr
          rm -rf /home/${cfg.name}/.nix-profile
        '';
      };
    };
  };
}
