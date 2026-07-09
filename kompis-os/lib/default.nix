# kompis-os/lib/default.nix
lib: inputs: org: rec {
  # pick a list of attributes from an attrSet
  pick = names: attrSet: lib.filterAttrs (name: _value: lib.elem name names) attrSet;

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
  semantic-colors = import ./semantic-colors.nix;

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
        url = lib.mkOption {
          description = "public url including scheme";
          default = "${config.scheme}://${config.endpoint}";
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
        scheme = lib.mkOption {
          description = "http or https";
          default = if config.ssl then "https" else "http";
          type = lib.types.str;
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
  wrapBins =
    pkgs: pkg: env:
    let
      wrapperArgs = lib.concatLists (
        lib.mapAttrsToList (name: value: [
          "--set"
          name
          value
        ]) env
      );
    in
    pkgs.symlinkJoin {
      name = "${pkg.name}-wrapped";
      paths = [ pkg ];
      nativeBuildInputs = [ pkgs.makeWrapper ];

      postBuild = ''
        for binary in $out/bin/*; do
          wrapProgram "$binary" ${lib.escapeShellArgs wrapperArgs}
        done
      '';
    };
}
