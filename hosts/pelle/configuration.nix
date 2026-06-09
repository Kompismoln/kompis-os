{
  org,
  ...
}:
{
  imports = [
    ../../kompis-os/nixos/glesys-updaterecord.nix
  ];

  kompis-os = {
    sysadm.rescueMode = true;
    glesys.updaterecord = {
      enable = true;
      recordid = "3959183";
      device = "enp5s0";
    };
    users = {
      alex = {
        description = org.user.alex.description;
        groups = [ "wheel" ];
      };
    };
  };
  systemd.services.nix-daemon.environment = {
    # Tells Node.js to prioritize IPv4 DNS resolutions over broken/cluttered IPv6 addresses
    NODE_OPTIONS = "--dns-result-order=ipv4first";
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
