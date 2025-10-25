{
  config,
  lib,
  ...
}:

{
  imports = [
    ../nixos/mysql.nix
    ../nixos/postgresql.nix
    ../nixos/redis.nix
  ];

  options.kompis-os.ide = {
    enable = lib.mkEnableOption "os-level services (e.g. databases) for IDE";
  };

  config = lib.mkIf config.kompis-os.ide.enable {
    kompis-os = {
      postgresql.enable = true;
      mysql.enable = true;
      redis.servers.test.enable = true;
    };
  };
}
