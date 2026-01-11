# apps/sverigesval.nix
{ org, ... }:
let
  name = "sverigesval";
  nextcloud = "nextcloud-kompismoln";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/nextcloud-rolf.nix
    ../kompis-os/nixos/nginx.nix
  ];
  kompis-os = {
    nginx.enable = true;
    users.${nextcloud}.members = [ "nginx" ];
    nextcloud-rolf.apps.${name} = {
      enable = true;
      endpoint = cfg.endpoint;
      user = nextcloud;
      siteRoot = "/var/lib/${nextcloud}/nextcloud/data/rolf/files/+pub/_site";
      sourceRoot = "/var/lib/${nextcloud}/nextcloud/data/rolf/files/+pub";
    };
  };
}
