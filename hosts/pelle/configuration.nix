{
  config,
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

  sops.secrets.wifi-keys = {
    owner = "wpa_supplicant";
    group = "wpa_supplicant";
  };

  networking.wireless = {
    enable = true;
    interfaces = [ "wlp4s0" ];
    secretsFile = config.sops.secrets."wifi-keys".path;
    networks."staple".pskRaw = "ext:psk_staple";
  };

  kompis-os = {
    glesys.updaterecord = {
      enable = false;
      recordid = "4069983";
      device = host.network.eth.interface;
    };
  };
}
