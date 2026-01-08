{
  kompis-os = {
    sysadm.rescueMode = true;
    users.ami.enable = true;
  };

  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  sops.secrets.wifi-keys = {
    mode = "644";
    owner = "ami";
  };

  services.pipewire.extraConfig.pipewire-pulse = {
    "99-echo-cancel" = {
      "pulse.cmd" = [
        {
          cmd = "load-module";
          args = "module-echo-cancel";
        }
      ];
      "stream.properties" = {
        "default.configured.audio.sink" = "echo-cancel-sink";
        "default.configured.audio.source" = "echo-cancel-source";
      };
    };
    "92-low-latency" = {
      stream.properties = {
        resample.quality = 10;
      };
    };
  };

  boot.extraModprobeConfig = ''
    options snd-hda-intel dmic_detect
  '';
}
