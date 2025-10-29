# kompis-os/apps/chatddx-dev.nix
{
  host,
  inputs,
  lib',
  org,
  ...
}:
let
  name = "chatddx-dev";
  appCfg = org.app.${name};
  package = inputs.${name}.packages.${host.system};
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
    svelte.apps."${name}-svelte" = {
      enable = true;
      inherit package;
      inherit (appCfg) endpoint;
      api_ssr = "http://localhost:${toString (lib'.ports "${name}-django")}";
    };

    redis.servers.${name} = {
      enable = true;
    };

    django.apps."${name}-django" = {
      enable = true;
      entity = name;
      inherit package;
      inherit (appCfg) endpoint;
      appname = "chatddx_backend";
      locationProxy = "/admin";
      celery = {
        enable = true;
        port = lib'.ports "${name}-redis";
      };
    };
  };
}
