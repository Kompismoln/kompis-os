# kompis-os/apps/chatddx.nix
{ org, ... }:
let
  name = "chatddx";
  appCfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/django.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
    ../kompis-os/nixos/redis.nix
    ../kompis-os/nixos/svelte.nix
  ];

  svelte.apps.${name} = {
    enable = true;
    entity = name;
    inherit (appCfg) endpoint;
  };

  django.apps.${name} = {
    enable = true;
    inherit (appCfg) endpoint;
    entity = name;
    packagename = "chatddx_backend";
    celery.enable = true;
    locationProxy = "/admin";
  };
}
