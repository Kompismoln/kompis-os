{
  lib,
  context,
  entity,
  ...
}:
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
    context.path + "/public-keys/${class}-${entity}-${key}.${ext}";
in
{
  options = lib.listToAttrs (
    map (
      key:
      lib.nameValuePair key (
        lib.mkOption {
          description = "${key} path for ${entity.class} ${entity.name}";
          type = lib.types.path;
          default = template entity.class entity.name key;
        }
      )
    ) context.classes.${entity.class}.keys
  );
}
