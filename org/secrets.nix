{
  context,
  lib,
  entity,
  ...
}:
{
  options = {
    sopsFile = lib.mkOption {
      default = context.path + "/enc/${entity.class}-${entity.name}.yaml";
      type = lib.types.path;
    };
    decryptionKey = lib.mkOption {
      default = "/keys/${entity.class}-${entity.name}";
      type = lib.types.str;
    };
  };
}
