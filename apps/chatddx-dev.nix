# kompis-os/apps/chatddx-dev.nix
{
  lib',
  org,
  ...
}:
let
  name = "chatddx-dev";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/django.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
    ../kompis-os/nixos/redis.nix
    ../kompis-os/nixos/svelte.nix
  ];

  kompis-os = {
    nginx.enable = true;
    postgresql.enable = true;
    users.${name}.class = "app";

    redis.servers."${name}-redis" = {
      enable = true;
      entity = name;
    };

    svelte.apps."${name}-svelte" = {
      enable = true;
      entity = name;
      inherit (cfg) endpoint;
      ssr = "http://localhost:${toString (lib'.ports "${name}-django")}";
    };

    django.apps."${name}-django" = {
      enable = true;
      entity = name;
      inherit (cfg) endpoint;
      djangoApp = "chatddx_backend";
      locationProxy = "/admin";
      celery = true;
      timeout = 180;
    };
  };
}
