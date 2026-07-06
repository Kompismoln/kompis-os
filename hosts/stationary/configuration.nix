{ host, ... }:
{
  imports = [
    ../../kompis-os/nixos/glesys-updaterecord.nix
  ];
  kompis-os = {
    sysadm.rescueMode = true;

    glesys.updaterecord = {
      enable = false;
      recordid = "4069984";
      device = host.externalInterface;
    };
  };

  boot.loader.grub.enable = true;

  networking = {
    useNetworkd = true;
    firewall = {
      logRefusedConnections = false;
    };
  };

  systemd.network = {
    enable = true;
    networks."10-${host.externalInterface}" = {
      matchConfig.Name = host.externalInterface;
      networkConfig.DHCP = "yes";
    };
  };

}
