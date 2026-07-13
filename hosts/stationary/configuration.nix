{ host, ... }:
{
  imports = [
    ../../kompis-os/nixos/glesys-updaterecord.nix
  ];
  kompis-os = {
    glesys.updaterecord = {
      enable = false;
      recordid = "4069984";
      device = host.network.eth.interface;
    };
  };
}
