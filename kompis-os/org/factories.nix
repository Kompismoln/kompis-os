{ lib, org, ... }:
let
  types = import ./types.nix {
    inherit lib org;
  };
  classes = import ./classes.nix;
in
rec {
  mkEntity =
    {
      name,
      config,
      class,
      ...
    }:
    {
      id = lib.mkOption {
        description = "numeric internal id used to seed other id's";
        default = null;
        type = with lib.types; nullOr int;
      };
      name = lib.mkOption {
        description = "name";
        default = name;
        type = lib.types.str;
      };
      class = lib.mkOption {
        description = "entity class";
        default = class;
        type = types.class;
      };
      description = lib.mkOption {
        description = "full name or short purpose description";
        default = "[${class}] ${config.name}";
        type = lib.types.str;
      };
      grants = lib.mkOption {
        type = with lib.types; listOf str;
      };
      principal = lib.mkOption {
        description = "entity id in various formats";
        type = with lib.types; nullOr (submodule (principalModule config));
        default = if config.id == null || class == "host" then null else { };
      };
      ids = lib.mkOption {
        description = "entity id in various formats";
        type = with lib.types; nullOr (submodule (idsModule config.id));
        default = if config.id == null then null else { };
      };
      settings = lib.mkOption {
        description = "entity-specific options, passed through as-is to the entity's configuration";
        type = lib.types.attrsOf lib.types.anything;
        default = { };
      };
      public-artifacts = mkPublicArtifacts config.class config.name;
      secrets = mkSecrets config.class config.name;

    };

  principalModule =
    entityConfig:
    { config, ... }:
    {
      options = {
        uid = lib.mkOption {
          description = "posix user id";
          default = classes.${entityConfig.class}.block + entityConfig.id;
          type = lib.types.int;
        };
        gid = lib.mkOption {
          description = "posix group id";
          default = config.uid;
          type = lib.types.int;
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
        home = lib.mkOption {
          description = "endow entity with /home (for users) or /var/lib (for non-users)";
          type = lib.types.str;
          default =
            if config.hasHome then
              (
                {
                  user = "/home/${entityConfig.name}";
                }
                .${entityConfig.class} or "/var/lib/${entityConfig.name}"
              )
            else
              "/var/empty";
        };
        homeMode = lib.mkOption {
          type = lib.types.str;
          default = "0750";
        };
        hasPasswd = lib.mkEnableOption "endow entity with a password" // {
          type = lib.types.bool;
          default = entityConfig.class == "user";
        };
        hasPublicKey = lib.mkEnableOption "endow entity with a cryptographic identity" // {
          type = lib.types.bool;
          default = builtins.elem entityConfig.class [
            "user"
            "service"
            "app"
          ];
        };
        hasHome = lib.mkEnableOption "force bash shell for non-normal users" // {
          type = lib.types.bool;
          default = builtins.elem entityConfig.class [
            "user"
            "store"
            "app"
          ];
        };
        hasBash = lib.mkEnableOption "force bash shell for non-normal users" // {
          type = lib.types.bool;
          default = entityConfig.class == "user";
        };
        bindAddress = lib.mkOption {
          description = "unique ipv6 loopback address for entity to bind to";
          default = "${org.loPrefix}::${toString config.uid}:${entityConfig.ids.hex4}";
          type = types.host6;
        };
      };
    };

  idsModule = id: {
    options =
      let
        hex = lib.toLower (lib.toHexString id);
      in
      {
        str = lib.mkOption {
          description = "id as string";
          type = lib.types.str;
          default = toString id;
        };
        hex = lib.mkOption {
          description = "id as hex";
          type = types.hextet;
          default = hex;
        };
        hex4 = lib.mkOption {
          description = "id as hex with fixed length 4";
          type = types.hextetP4;
          default = lib.strings.fixedWidthString 4 "0" hex;
        };
        hex8 = lib.mkOption {
          description = "id as hex with fixed length 8";
          type = types.hextetP8;
          default = lib.strings.fixedWidthString 8 "0" hex;
        };
        hex32 = lib.mkOption {
          description = "id as hex with fixed length 32";
          type = types.hextetP32;
          default = lib.strings.fixedWidthString 32 "0" hex;
        };
      };
  };

  mkSecrets =
    class: entity:
    (lib.mkOption {
      description = "paths for secrets";
      type = lib.types.submodule {
        options = {
          sopsFile = lib.mkOption {
            default = ../../enc/${class}-${entity}.yaml;
            type = lib.types.path;
          };
          decryptionKey = lib.mkOption {
            default = "/keys/${class}-${entity}";
            type = lib.types.str;
          };
        };
      };
    });

  mkPublicArtifacts =
    class: entity:
    let
      template =
        class: entity: key:
        let
          exts = {
            tls-cert = "pem";
            default = "pub";
          };
          ext = exts.${key} or exts.default;
        in
        ../../public-keys/${class}-${entity}-${key}.${ext};
    in
    lib.mkOption {
      description = "registry for key files";
      type = lib.types.submodule {
        options = lib.listToAttrs (
          map (
            key:
            lib.nameValuePair key (
              lib.mkOption {
                description = "${key} path for ${class} ${entity}";
                type = lib.types.path;
                default = template class entity key;
              }
            )
          ) classes.${class}.keys
        );
      };
    };
}
