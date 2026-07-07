{ host, ... }:
{
  boot = {
    loader.grub.enable = true;
  };

  hardware.facter.detected.dhcp = {
    interfaces = [ ];
  };

  networking = {
    useDHCP = false;
    useNetworkd = true;
    firewall = {
      logRefusedConnections = false;
    };
  };

  systemd.network =
    let
      cfg = host.network.eth;
    in
    {
      enable = true;
      networks."10-${cfg.interface}" = {
        matchConfig.Name = cfg.interface;
        networkConfig = {
          Address = [
            cfg.address4
            cfg.address
          ];
          DNS = cfg.dns;
        };
        routes = [
          {
            Destination = "0.0.0.0/0";
            Gateway = cfg.gateway4;
            GatewayOnLink = true;
          }
          {
            Destination = "::/0";
            Gateway = cfg.gateway;
            GatewayOnLink = true;
          }
        ];
      };
    };

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

  kompis-os = {
    sysadm.rescueMode = true;
    nginx.monitor = true;
  };
}
