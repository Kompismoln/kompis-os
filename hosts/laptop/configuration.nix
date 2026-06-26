{ org, config, ... }:
{

  systemd.network = {
    enable = true;
    links."10-wol" = {
      matchConfig.Type = "ether";
      linkConfig.WakeOnLan = "magic";
    };
    networks."10-ethernet" = {
      matchConfig.Type = "ether";
      networkConfig.DHCP = "yes";
    };
  };
  networking = {
    useDHCP = false;
  };
  boot = {
    blacklistedKernelModules = [
      "ax88179_178a"
      "asix"
      "cdc_ncm"
    ];

    extraModulePackages = [
      (config.boot.kernelPackages.callPackage ../../kompis-os/kernel/mod-ax88179.nix { })
    ];

    kernelModules = [ "ax_usb_nic" ];
    loader = {
      grub.enable = true;
    };
  };
  kompis-os = {
    sysadm.rescueMode = true;
    users = {
      alex = {
        description = org.user.alex.description;
        groups = [ "wheel" ];
      };
    };
  };
}
