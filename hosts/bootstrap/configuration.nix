{ lib, ... }:
{
  boot.loader.grub.enable = false;
  boot.loader.systemd-boot.enable = false;

  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
  };

  networking.networkmanager.enable = true;
  networking.useDHCP = false;
  kompis-os = {
    sysadm.rescueMode = true;
  };

  environment.etc."key.txt" = {
    text = "AGE-SECRET-KEY-1N0D6L0YKFSJZGMJMC48VVHV2M8J3UXD7UVCNLVN2VAVTHJC5G43S3Z88WR";
  };

  users.users.root = {
    password = "root";
    hashedPassword = lib.mkForce null;
  };

  sops.age.keyFile = lib.mkForce "/etc/key.txt";
}
