{
  #services.nginx.virtualHosts."kompismoln.se" = {
  #  root = inputs.kompismoln-site.packages."x86_64-linux".default;
  #
  #  locations."/" = {
  #    tryFiles = "$uri $uri/ =404";
  #  };
  #
  #  forceSSL = true;
  #  enableACME = true;
  #};
}
