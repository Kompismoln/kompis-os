{ org, config, ... }:
{

  systemd.network = {
    enable = true;
    links."10-wake-on-lan" = {
      matchConfig.Type = "ether";
      linkConfig.WakeOnLan = "magic";
    };
  };
  networking = {
    useNetworkd = true;
  };
  boot = {
    blacklistedKernelModules = [
      "ax88179_178a"
      "asix"
    ];

    extraModulePackages = [
      (config.boot.kernelPackages.callPackage ../../kompis-os/kernel/ax88179 { })
    ];

    kernelModules = [ "ax_usb_nic" ];
    loader = {
      grub.enable = true;
    };
  };
  kompis-os = {
    users = {
      alex = {
        description = org.user.alex.description;
        groups = [ "wheel" ];
      };
    };
  };
}
