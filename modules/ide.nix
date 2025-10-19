{
  config,
  lib,
  pkgs,
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

  cfg = config.kompis-os.ide;
  eachUser = filterAttrs (user: cfg: cfg.enable) cfg;
  eachHMUser = filterAttrs (user: cfg: config.kompis-os.hm.${user}.enable) eachUser;

  userOpts = {
    options = {
      enable = mkEnableOption "IDE for this user";
      postgresql = mkEnableOption "a postgres db with same name";
      mysql = mkEnableOption "a mysql db with same name";
      redis = mkEnableOption "a redis db";
    };
  };
in
{
  options.kompis-os.ide =
    with types;
    mkOption {
      description = "Set of users to be configured with IDE.";
      type = attrsOf (submodule userOpts);
      default = { };
    };

  config = mkIf (eachUser != { }) {
    home-manager.users = mapAttrs (user: cfg: {
      kompis-os-hm.ide = {
        enable = true;
        name = config.kompis-os.users.${user}.description;
        inherit (config.kompis-os.users.${user}) email;
      };
    }) eachHMUser;

    services.redis.servers = mapAttrs (user: cfg: {
      enable = cfg.redis;
      user = user;
    }) eachUser;

    programs.vim = {
      enable = true;
      defaultEditor = true;
    };

    environment.systemPackages = with pkgs; [
      sqlitebrowser
      python3
      payload-dumper-go
      nodejs
    ];

    programs.adb.enable = true;
    programs.npm.enable = true;

    users.users = mapAttrs (user: cfg: {
      extraGroups = [
        "adbusers"
        "docker"
      ];
    }) eachUser;

    kompis-os.postgresql = mapAttrs (user: cfg: { ensure = cfg.postgresql; }) eachUser;
    kompis-os.mysql = mapAttrs (user: cfg: { ensure = cfg.mysql; }) eachUser;
  };
}
