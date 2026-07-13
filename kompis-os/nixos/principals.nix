# nixos/principals.nix
{
  config,
  lib,
  org,
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.principals;
  eachUser = lib.filterAttrs (_user: cfg: cfg.enable) cfg;

  principalOpts =
    { name, config, ... }:
    {
      options = {
        enable = lib.mkEnableOption "this principal" // {
          default = true;
        };
        class = lib.mkOption {
          description = "principal's entity class";
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
        passwd = lib.mkEnableOption "endow principal with a password" // {
          default = config.class == "user";
        };
        publicKey = lib.mkEnableOption "endow principal with a cryptographic identity" // {
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
        shell = lib.mkEnableOption "force bash shell for non-normal principals" // {
          default = false;
          type = lib.types.bool;
        };
        groups = lib.mkOption {
          description = "principal's extra groups";
          type = with lib.types; listOf str;
          default = [ ];
        };
        members = lib.mkOption {
          description = "members of the principal's groups";
          type = with lib.types; listOf str;
          default = [ ];
        };
      };
    };
in
{
  options.kompis-os.principals = lib.mkOption {
    description = "Set of principal to be configured.";
    type = with lib.types; attrsOf (submodule principalOpts);
    default = { };
  };

  config = lib.mkIf (cfg != { }) {

    sops.secrets = lib.mapAttrs' (
      user: userCfg:
      lib.nameValuePair "${user}/passwd-sha512" {
        neededForUsers = true;
        inherit (org.${userCfg.class}.${user}.secrets) sopsFile;
      }
    ) (lib.filterAttrs (_user: userCfg: userCfg.passwd) eachUser);

    users = {
      mutableUsers = false;
      users = lib.mapAttrs (
        user: userCfg:
        let
          isNormalUser = userCfg.class == "user";
          publicKey = org.${userCfg.class}.${user}.public-artifacts.ssh-key;
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
          inherit (userCfg) homeMode description;
          inherit isNormalUser home;
          isSystemUser = !isNormalUser;
          uid = org.${userCfg.class}.${user}.id;
          group = user;
          extraGroups = userCfg.groups;
          openssh.authorizedKeys.keyFiles = lib.mkIf userCfg.publicKey [ publicKey ];
          hashedPasswordFile = lib.mkIf userCfg.passwd passwordFile;
          shell = lib.mkIf userCfg.shell pkgs.bash;
          createHome = home != "/var/empty";
        }
      ) eachUser;

      groups = lib.mapAttrs (user: userCfg: {
        gid = org.${userCfg.class}.${user}.id;
        members = [ user ] ++ userCfg.members;
      }) eachUser;
    };

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

    kompis-os.preserve.directories = lib.mapAttrsToList (user: _userCfg: {
      directory = config.users.users.${user}.home;
      inherit user;
      group = user;
    }) (lib.filterAttrs (_user: userCfg: userCfg.stateful) eachUser);
  };
}
