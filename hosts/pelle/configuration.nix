{
  org,
  ...
}:
{
  kompis-os = {
    sysadm.rescueMode = true;
    users = {
      alex = {
        description = org.user.alex.description;
        groups = [ "wheel" ];
      };
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    useDHCP = false;
  };

  systemd.network = {
    enable = true;
    networks."10-enp5s0" = {
      matchConfig.Name = "enp5s0";
      networkConfig.DHCP = "yes";
    };
  };
}
