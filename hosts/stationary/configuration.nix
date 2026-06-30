{
  kompis-os = {
    sysadm.rescueMode = true;
  };

  boot.loader.grub.enable = true;

  networking = {
    useDHCP = false;
    firewall = {
      logRefusedConnections = false;
      allowedTCPPorts = [ 53 ];
      allowedUDPPorts = [ 53 ];
    };
  };

  systemd.network = {
    enable = true;
    networks."10-enp3s0" = {
      matchConfig.Name = "enp3s0";
      networkConfig.DHCP = "yes";
    };
  };

}
