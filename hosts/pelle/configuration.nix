{
  host,
  #lib,
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
    glesys.updaterecord = {
      enable = false;
      recordid = "4069983";
      device = host.network.eth.interface;
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
}
