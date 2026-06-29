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

  services.pipewire.extraConfig.pipewire."99-echo-cancel" = {
    "context.modules" = [
      {
        name = "libpipewire-module-echo-cancel";
        args = {
          "node.latency" = "1024/48000";
          "capture.props" = {
            "node.name" = "echo-cancel-source";
          };
          "sink.props" = {
            "node.name" = "echo-cancel-sink";
          };
        };
      }
    ];
  };
}
