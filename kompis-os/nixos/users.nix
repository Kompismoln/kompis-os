# kompis-os/nixos/users.nix
{
  config,
  lib,
  lib',
  org,
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.users;
  eachUser = lib.filterAttrs (user: cfg: cfg.enable) cfg;

  userOpts =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "this user" // {
          default = true;
        };
        class = lib.mkOption {
          description = "user's entity class";
          default = "user";
          type = lib.types.enum [
            "user"
            "service"
            "app"
            "system"
            "store"
          ];
        };
        description = lib.mkOption {
          default = name;
          type = lib.types.str;
        };
        passwd = lib.mkEnableOption "endow user with a password" // {
          default = config.class == "user";
        };
        publicKey = lib.mkEnableOption "endow user with a cryptographic identity" // {
          default = builtins.elem config.class [
            "user"
            "service"
            "app"
          ];
        };
        home = lib.mkEnableOption "force home at /home for normal users or /var/lib for others" // {
          default = builtins.elem config.class [
            "user"
            "app"
            "store"
          ];
          type = lib.types.bool;
        };
        homeMode = lib.mkOption {
          type = lib.types.str;
          default = "0750";
        };
        stateful = lib.mkEnableOption "preserve home" // {
          default = config.home;
        };
        shell = lib.mkEnableOption "force bash shell for non-normal users" // {
          default = false;
          type = lib.types.bool;
        };
        email = lib.mkOption {
          description = "user's primary email";
          default = "${name}@${org.domain}";
          type = with lib.types; nullOr str;
        };
        groups = lib.mkOption {
          description = "user's extra groups";
          type = with lib.types; listOf str;
          default = [ ];
        };
        members = lib.mkOption {
          description = "members of the user's groups";
          type = with lib.types; listOf str;
          default = [ ];
        };
      };
    };
in
{
  options.kompis-os.users = lib.mkOption {
    description = "Set of users to be configured.";
    type = with lib.types; attrsOf (submodule userOpts);
    default = { };
  };

  config = lib.mkIf (cfg != { }) {
    users.mutableUsers = false;

    sops.secrets = lib.mapAttrs' (
      user: userCfg:
      lib.nameValuePair "${user}/passwd-sha512" {
        neededForUsers = true;
        sopsFile = lib'.secrets userCfg.class user;
      }
    ) (lib.filterAttrs (user: userCfg: userCfg.passwd) eachUser);

    users.users = lib.mapAttrs (
      user: userCfg:
      let
        isNormalUser = userCfg.class == "user";
        publicKey = lib'.public-artifacts userCfg.class user "ssh-key";
        passwordFile = config.sops.secrets."${user}/passwd-sha512".path;
        home =
          if !userCfg.home then
            "/var/empty"
          else if isNormalUser then
            "/home/${user}"
          else
            "/var/lib/${user}";
      in
      {
        inherit (userCfg) homeMode;
        inherit isNormalUser home;
        isSystemUser = !isNormalUser;
        description = userCfg.description;
        uid = lib'.ids.${user};
        group = user;
        extraGroups = userCfg.groups;
        openssh.authorizedKeys.keyFiles = lib.mkIf userCfg.publicKey [ publicKey ];
        hashedPasswordFile = lib.mkIf userCfg.passwd passwordFile;
        shell = lib.mkIf userCfg.shell pkgs.bash;
        createHome = home != "/var/empty";
      }
    ) eachUser;

    users.groups = lib.mapAttrs (user: userCfg: {
      gid = lib'.ids.${user};
      members = [ user ] ++ userCfg.members;
    }) eachUser;

    # hack to prevent activation errors with service-users (with uid=2000+)
    systemd.services = lib.mapAttrs' (
      user: userCfg:
      lib.nameValuePair "user@${toString lib'.ids.${user}}" {
        restartIfChanged = false;
      }
    ) (lib.filterAttrs (user: userCfg: lib'.ids.${user} > 1999) eachUser);

    assertions = lib.mapAttrsToList (
      user: userCfg:
      let
        home = config.users.users.${user}.home;
      in
      {
        assertion = !(userCfg.stateful && home == "/var/empty");
        message = "Stateful user '${user}' must have a real home";
      }
    ) eachUser;

    kompis-os.preserve.directories = lib.mapAttrsToList (user: userCfg: {
      directory = config.users.users.${user}.home;
      user = user;
      group = user;
    }) (lib.filterAttrs (user: userCfg: userCfg.stateful) eachUser);
  };
}
