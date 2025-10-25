{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.kompis-os-hm.nix-conf = {
    enable = lib.mkEnableOption "nix config";
  };

  config = lib.mkIf config.kompis-os-hm.nix-conf.enable {
    nix = {
      package = lib.mkForce pkgs.lix;
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
      };
    };
  };
}
