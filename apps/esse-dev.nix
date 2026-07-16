{ app, ... }:
{
  imports = [
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/redis.nix
    ../kompis-os/nixos/mysql.nix
    ../kompis-os/nixos/wordpress.nix
  ];

  kompis-os = {
    nginx.enable = true;
    mysql = {
      enable = true;
    };

    redis.servers.${app.name} = {
      enable = true;
      user = app.name;
      home = "${app.principal.home}/redis";
      bind = app.principal.bindAddress;
    };

    wordpress.apps.${app.name} = {
      enable = true;
      home = "${app.principal.home}/wordpress";
      inherit (app) endpoint name;
      inherit (app.principal) bindAddress;
    };
  };
}
