{
  kompis-os = {
    sysadm.rescueMode = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    useDHCP = false;
    enableIPv6 = false;
  };

  systemd.network = {
    enable = true;
    networks."10-enp5s0" = {
      matchConfig.Name = "enp5s0";
      networkConfig.DHCP = "ipv4";
    };
  };
}
