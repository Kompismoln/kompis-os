{
  host,
  #lib,
  org,
  ...
}:
{
  imports = [
    ../../kompis-os/nixos/glesys-updaterecord.nix
  ];

  nix = {

    settings = {
      #max-jobs = lib.mkForce 1;
      #cores = lib.mkForce 8;
      substituters = [
        "https://cache.nixos-cuda.org"
      ];
      trusted-public-keys = [
        "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
      ];
    };
  };
  kompis-os = {
    sysadm.rescueMode = true;

    glesys.updaterecord = {
      enable = false;
      recordid = "4069983";
      device = host.externalInterface;
    };

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
