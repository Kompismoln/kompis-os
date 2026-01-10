# kompis-os/lib/default.nix
lib: inputs: rec {
  # pick a list of attributes from an attrSet
  pick = names: attrSet: lib.filterAttrs (name: value: lib.elem name names) attrSet;

  # create an env-file that can be sourced to set environment variables
  envToList = env: lib.mapAttrsToList (name: value: "${name}=${toString value}") env;

  # loop over an attrSet and merge the attrSets returned from f into one
  # (latter override the former in case of conflict)
  mergeAttrs =
    f: attrs:
    lib.foldlAttrs (
      acc: name: value:
      (lib.recursiveUpdate acc (f name value))
    ) { } attrs;
  ids = (import ./ids.nix) // inputs.org.ids;
  semantic-colors = import ./semantic-colors.nix;

  public-artifacts =
    class: entity: key:
    let
      template =
        if lib.hasAttr key inputs.org.public-artifacts then
          inputs.org.public-artifacts.${key}
        else
          inputs.org.public-artifacts.default;
      location = builtins.replaceStrings [ "$class" "$entity" "$key" ] [ class entity key ] template;
    in
    "${inputs.self}/${location}";

  ports = entity: ids.${entity} + 10000;
  secrets =
    class: entity:
    let
      template =
        if lib.hasAttr class inputs.org.secrets then
          inputs.org.secrets.${class}
        else
          inputs.org.secrets.default;
      location = builtins.replaceStrings [ "$class" "$entity" ] [ class entity ] template;
    in
    "${inputs.self}/${location}";

  host-config =
    host:
    let
      location = builtins.replaceStrings [ "$host" ] [ host ] inputs.org.host-config;
    in
    "${inputs.self}/${location}";

  home-config =
    home:
    let
      location = builtins.replaceStrings [ "$home" ] [ home ] inputs.org.home-config;
    in
    "${inputs.self}/${location}";

  app-config =
    app:
    let
      location = builtins.replaceStrings [ "$app" ] [ app ] inputs.org.app-config;
    in
    "${inputs.self}/${location}";

  home-args =
    user: host:
    let
      hostCfg = inputs.org.host.${host} or (throw "Host '${host}' not found in org.host");
      homeCfg = hostCfg.home.${user} or (throw "User '${user}' not found in org.host.${host}.home");
    in
    {
      inherit (hostCfg) system stateVersion;
      roles = homeCfg.roles or [ ];
      hostname = host;
      username = user;
      configPath = home-config "${user}@${host}";
    };

  package-sets = import ../packages/sets.nix;

  mkAppOpts =
    host: appType: submodule:
    { name, config, ... }@args:
    let
      options = {
        enable = lib.mkEnableOption appType;
        endpoint = lib.mkOption {
          description = "canonical domain name";
          type = lib.types.str;
        };
        location = lib.mkOption {
          description = "canonical path";
          default = "/";
          type = lib.types.str;
        };
        entity = lib.mkOption {
          description = "entity name";
          default = name;
          type = lib.types.str;
        };
        input = lib.mkOption {
          description = "app flake input name";
          default = config.entity;
          type = lib.types.str;
        };
        database = lib.mkOption {
          description = "app's database";
          default = config.entity;
          type = lib.types.str;
        };
        user = lib.mkOption {
          description = "app's system user";
          default = config.entity;
          type = lib.types.str;
        };
        home = lib.mkOption {
          description = "path to app's filesystem";
          default = "/var/lib/${config.entity}/${appType}";
          type = lib.types.str;
        };
        ssl = lib.mkOption {
          description = "let's encrypt and force https";
          default = true;
          type = lib.types.bool;
        };
        package = lib.mkOption {
          description = "${appType}'s default package";
          default = inputs.${config.input}.packages.${host.system}.default;
          type = lib.types.package;
        };
        packages = lib.mkOption {
          description = "${appType}'s packages";
          default = inputs.${config.input}.packages.${host.system};
          type = with lib.types; attrsOf package;
        };
        migration = lib.mkOption {
          description = "expected state version";
          default = null;
          type = with lib.types; nullOr str;
        };
      };
    in
    lib.recursiveUpdate { inherit options; } (
      if lib.isFunction submodule then submodule args else submodule
    );
  diskoFlakeModule =
    {
      lib,
      ...
    }:
    {
      options.flake.diskoModules = lib.mkOption {
        type = lib.types.lazyAttrsOf lib.types.raw;
      };
    };
}
