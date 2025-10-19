{
  config,
  host,
  inputs,
  lib,
  lib',
  org,

  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.kompis-os.hm;
  eachUser = filterAttrs (user: cfg: cfg.enable) cfg;

  userOpts = {
    options.enable = mkEnableOption "home-manager for this user";
  };
in
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];

  options.kompis-os.hm =
    with types;
    mkOption {
      description = "Set of users to be configured with home-manager.";
      type = attrsOf (submodule userOpts);
      default = { };
    };

  config = mkIf (eachUser != { }) {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;
      extraSpecialArgs = {
        inherit inputs lib' org;
      };
      sharedModules = [ ../hm-modules/all.nix ];
      users = mapAttrs (user: cfg: {
        home.stateVersion = host.stateVersion;
        home.username = user;
        kompis-os-hm.user = {
          enable = config.kompis-os.hm.${user}.enable;
          name = user;
          uid = lib'.ids.${user}.uid;
        };
      }) eachUser;
    };
  };
}
