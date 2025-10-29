{ org, ... }:
{
  imports = [
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/redis.nix
    ../kompis-os/nixos/mysql.nix
    ../kompis-os/nixos/wordpress.nix
  ];

  wordpress.sites."esse" = {
    enable = true;
    appname = "esse";
    hostname = org.app.esse.endpoint;
    www = "yes";
  };
}
