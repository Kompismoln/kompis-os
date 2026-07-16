{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
    };
  };

  services.pipewire.extraConfig.pipewire."99-echo-cancel" = {
    "context.modules" = [
      {
        name = "libpipewire-module-echo-cancel";
        args = {
          "monitor.mode" = true;
          "node.latency" = "1024/48000";
          "capture.props" = {
            "node.name" = "echo-cancel-source";
          };
          "source.props" = {
            "node.name" = "Echo Cancellation Source";
          };
        };
      }
    ];
  };

}
