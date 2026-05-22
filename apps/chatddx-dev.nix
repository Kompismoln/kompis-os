# kompis-os/apps/chatddx-dev.nix
{
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

    django.apps."${name}-django" = {
      enable = true;
      entity = name;
      inherit (cfg) endpoint;
      djangoApp = "chatddx.django";
      locationProxy = "/admin";
      timeout = 180;
    };
  };
}
