{ org, ... }:
{
  nextcloud-rolf.sites."sverigesval-sync" = {
    enable = true;
    hostname = org.app.sverigesval.endpoint;
    username = "nextcloud-kompismoln";
    www = "redirect";
    siteRoot = "/var/lib/nextcloud-kompismoln/nextcloud/data/rolf/files/+pub/_site";
    sourceRoot = "/var/lib/nextcloud-kompismoln/nextcloud/data/rolf/files/+pub";
  };

  services.nginx.virtualHosts."admin.sverigesval.org" = {
    forceSSL = true;
    enableACME = true;
    locations."/".return = "301 https://nextcloud.kompismoln.se$request_uri";
  };

}
