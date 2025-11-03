{ org, ... }:
let
  name = "esse-dev";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/redis.nix
    ../kompis-os/nixos/mysql.nix
    ../kompis-os/nixos/wordpress.nix
  ];

  kompis-os = {
    nginx.enable = true;
    mysql.enable = true;
    users.${name} = {
      class = "app";
      members = [ "nginx" ];
    };

    redis.servers."${name}-redis" = {
      enable = true;
      entity = name;
    };

    wordpress.apps.${name} = {
      enable = true;
      inherit (cfg) endpoint;
    };
  };
}
