{ org, ... }:
let
  name = "sverigesval-dev";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/nextcloud-rolf.nix
    ../kompis-os/nixos/nginx.nix
  ];
  kompis-os = {
    nginx.enable = true;
    users."nextcloud-kompismoln-dev".members = [ "nginx" ];
    nextcloud-rolf.apps.${name} = {
      enable = true;
      endpoint = cfg.endpoint;
      user = "nextcloud-kompismoln-dev";
      siteRoot = "/var/lib/nextcloud-kompismoln-dev/nextcloud/data/rolf/files/+pub/_site";
      sourceRoot = "/var/lib/nextcloud-kompismoln-dev/nextcloud/data/rolf/files/+pub";
    };
  };
}
