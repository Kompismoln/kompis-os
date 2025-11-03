{ org, ... }:
let
  name = "sverigesval";
  cfg = org.app.${name};
in
{
  nextcloud-rolf.apps.${name} = {
    enable = true;
    endpoint = cfg.endpoint;
    username = "nextcloud-kompismoln";
    siteRoot = "/var/lib/nextcloud-kompismoln/nextcloud/data/rolf/files/+pub/_site";
    sourceRoot = "/var/lib/nextcloud-kompismoln/nextcloud/data/rolf/files/+pub";
  };

  services.nginx.virtualHosts."admin.sverigesval.org" = {
    forceSSL = true;
    enableACME = true;
    locations."/".return = "301 https://nextcloud.kompismoln.se$request_uri";
  };

}
