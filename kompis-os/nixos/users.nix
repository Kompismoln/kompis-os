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
        passwd = lib.mkEnableOption "password" // {
          default = config.class == "user";
        };
        publicKey = lib.mkEnableOption "public key" // {
          default = true;
        };
        stateful = lib.mkEnableOption "this entity has a state" // {
          type = lib.types.bool;
          default = builtins.elem config.class [
            "app"
            "user"
          ];
        };
        class = lib.mkOption {
          description = "user's entity class";
          default = "user";
          type = lib.types.enum [
            "user"
            "service"
            "app"
            "system"
          ];
        };
        description = lib.mkOption {
          default = name;
          type = lib.types.str;
        };
        home = lib.mkOption {
          description = "force home at /var/lib for system users";
          default = config.class == "app";
          type = lib.types.bool;
        };
        shell = lib.mkOption {
          description = "force bash shell for system users";
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
      in
      {
        inherit isNormalUser;
        isSystemUser = !isNormalUser;
        description = userCfg.description;
        uid = lib'.ids.${user};
        group = user;
        extraGroups = userCfg.groups;
        homeMode = lib.mkIf (userCfg.class == "app") "0750";
        openssh.authorizedKeys.keyFiles = lib.mkIf userCfg.publicKey [ publicKey ];
        hashedPasswordFile = lib.mkIf userCfg.passwd passwordFile;
        shell = lib.mkIf userCfg.shell pkgs.bash;
        home = lib.mkIf userCfg.home "/var/lib/${user}";
        createHome = lib.mkIf userCfg.home true;
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
        assertion = !userCfg.stateful || home != "/var/empty";
        message = "Stateful user '${user}' cannot have home '${home}'";
      }
    ) eachUser;

    kompis-os.preserve.directories =
      lib.mapAttrsToList
        (user: userCfg: {
          directory = config.users.users.${user}.home;
          user = user;
          group = user;
        })
        (
          lib.filterAttrs (user: userCfg: toString config.users.users.${user}.home != "/var/empty") eachUser
        );
  };
}
