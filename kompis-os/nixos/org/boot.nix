{ host, ... }:
let
  boots = {
    systemd = {
      loader = {
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
      };
    };
    grub = {
      loader.grub.enable = true;
    };
  };
in
{
  boot = boots.${host.boot};
}
