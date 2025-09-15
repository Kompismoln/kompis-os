{ config, ... }:

{
  services.prometheus = {
    exporters.node = {
      enable = true;
      enabledCollectors = [ "systemd" ];
    };
    scrapeConfigs = [
      {
        job_name = "node";
        static_configs = with config.services.prometheus.exporters; [
          {
            targets = [
              "glesys.ahbk:${toString node.port}"
              "stationary.ahbk:${toString node.port}"
              "laptop.ahbk:${toString node.port}"
            ];
          }
        ];
      }
    ];
  };
}
