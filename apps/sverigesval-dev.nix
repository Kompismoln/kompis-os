# apps/sverigesval-dev.nix
{
  app,
  inputs,
  org,
  host,
  ...
}:
let
  nextcloud = org.app.nextcloud-kompismoln-dev;
in
{
  imports = [
    ../kompis-os/nixos/nextcloud-rolf.nix
    ../kompis-os/nixos/nginx.nix
  ];
  kompis-os = {
    nginx.enable = true;
    nextcloud-rolf.apps.${app.name} = {
      enable = true;
      inherit (app) endpoint name;
      packages = inputs.${app.name}.packages.${host.system};
      user = nextcloud.name;
      home = "${nextcloud.principal.home}/nextcloud/data/rolf/files/+pub";
    };
  };
}
