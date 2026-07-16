# apps/nextcloud-kompismoln-dev.nix
{
  app,
  config,
  org,
  ...
}:
let
  collabora = org.app.collabora-dev;
in
{
  imports = [
    ../kompis-os/nixos/collabora.nix
    ../kompis-os/nixos/nextcloud.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  sops.secrets."${app.name}/secret-key" = {
    inherit (app.secrets) sopsFile;
    owner = app.name;
    group = app.name;
  };

  kompis-os = {
    postgresql.enable = true;
    nginx.enable = true;

    nextcloud.apps.${app.name} = {
      enable = true;
      inherit (app) endpoint name;
      inherit (app.principal) bindAddress gid uid;
      home = "${app.principal.home}/nextcloud";
      user = app.name;
      database = app.name;
      secretKeyPath = config.sops.secrets."${app.name}/secret-key".path;
      collaboraEndpoint = collabora.endpoint;
    };
  };
}
