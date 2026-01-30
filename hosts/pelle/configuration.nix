{ lib, pkgs, ... }:
{
  kompis-os = {
    sysadm.rescueMode = true;
    glesys.updaterecord = {
      enable = true;
      recordid = "3959183";
      device = "enp5s0";
    };
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  networking = {
    useDHCP = false;
    enableIPv6 = false;
  };

  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "nvidia-x11"
      "nvidia-settings"
      "cuda_cudart"
      "cuda_nvcc"
      "cuda_cccl"
      "libcublas"
    ];

  hardware.nvidia.open = false;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.graphics.enable = true;

  services.ollama = {
    enable = true;
    models = "/srv/models/ollama";
    host = "0.0.0.0";
    package = pkgs.ollama-cuda;
    home = "/var/lib/private/ollama";
    user = "ollama";
    loadModels = [
      "llama3.1"
      "medllama2"
      "gemma3:4b"
      "gemma3:12b"
    ];
  };

  kompis-os.paths."/srv/models/ollama" = {
    user = "ollama";
  };

  systemd.network = {
    enable = true;
    networks."10-enp5s0" = {
      matchConfig.Name = "enp5s0";
      networkConfig.DHCP = "ipv4";
    };
  };
}
