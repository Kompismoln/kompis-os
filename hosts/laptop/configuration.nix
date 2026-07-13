{ config, ... }:
{
  systemd.network.links."10-wake-on-lan" = {
    matchConfig.Type = "ether";
    linkConfig.WakeOnLan = "magic";
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
  };
}
