{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kompis-os = {
    org-json = lib.mkOption {
      description = "org.json as a package";
      type = lib.types.package;
    };
    org = lib.mkOption {
      description = "calculated org.toml";
      # allow a very loose type on account of org.toml still being unstable
      type = with lib.types; attrsOf anything;
    };
  };

  config = {
    kompis-os.org-json = pkgs.writeTextFile {
      name = "org.json";
      text = builtins.toJSON config.kompis-os.org;
    };
  };
}
