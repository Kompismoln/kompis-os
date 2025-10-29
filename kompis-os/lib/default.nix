# kompis-os/lib/default.nix
lib: inputs: rec {
  # pick a list of attributes from an attrSet
  pick = attrNames: attrSet: lib.filterAttrs (name: value: lib.elem name attrNames) attrSet;

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
      path = builtins.replaceStrings [ "$class" "$entity" "$key" ] [ class entity key ] template;
    in
    "${inputs.self}/${path}";

  ports = entity: ids.${entity} + 10000;
  secrets =
    class: entity:
    let
      template =
        if lib.hasAttr class inputs.org.secrets then
          inputs.org.secrets.${class}
        else
          inputs.org.secrets.default;
      path = builtins.replaceStrings [ "$class" "$entity" ] [ class entity ] template;
    in
    "${inputs.self}/${path}";

  host-config =
    host:
    let
      path = builtins.replaceStrings [ "$host" ] [ host ] inputs.org.host-config;
    in
    "${inputs.self}/${path}";

  home-config =
    home:
    let
      path = builtins.replaceStrings [ "$home" ] [ home ] inputs.org.home-config;
    in
    "${inputs.self}/${path}";

  app-config =
    app:
    let
      path = builtins.replaceStrings [ "$app" ] [ app ] inputs.org.app-config;
    in
    "${inputs.self}/${path}";

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

  homes = lib.concatMapAttrs (
    host: hostCfg:
    lib.mapAttrs' (username: homeCfg: {
      name = "${username}@${host}";
      value = home-args username host;
    }) (hostCfg.home or { })
  ) inputs.org.host;

  mkAppOpts =
    host: appType: submodule:
    { name, ... }@args:
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
        ssl = lib.mkOption {
          description = "force https";
          default = true;
          type = lib.types.bool;
        };
        port = lib.mkOption {
          description = "allocated port";
          default = ids.${name} + 10000;
          type = lib.types.port;
        };
        uid = lib.mkOption {
          description = "user and group id";
          type = lib.types.int;
          default = ids.${name};
        };
        package = lib.mkOption {
          description = "${appType}'s package(s)";
          default = inputs.${name}.packages.${host.system}.default;
          type = with lib.types; either package (attrsOf package);
        };
        entity = lib.mkOption {
          description = "belongs to this entity";
          default = name;
          type = lib.types.str;
        };
      };
    in
    lib.recursiveUpdate { inherit options; } (
      if lib.isFunction submodule then submodule args else submodule
    );
}
