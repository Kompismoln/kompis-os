{
  imports = [
    ../../kompis-os/nixos/glesys-updaterecord.nix
  ];

  kompis-os = {
    sysadm.rescueMode = true;

    glesys.updaterecord = {
      enable = true;
      recordid = "3754970";
      device = "enp3s0";
    };
  };

  boot.loader.grub.enable = true;

  networking = {
    useDHCP = false;
    enableIPv6 = false;
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
      networkConfig.DHCP = "ipv4";
    };
  };

}
