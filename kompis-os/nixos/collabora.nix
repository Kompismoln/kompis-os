{
  config,
  host,
  lib,
  lib',
  org,
  ...
}:
let
  cfg = config.kompis-os.collabora;
  appOpts = lib'.mkAppOpts host "collabora" {
    options = {
      app = lib.mkOption {
        description = "name";
        type = lib.types.str;
      };
      allowedHosts = lib.mkOption {
        description = "Accept WOPI from these hosts";
        type = with lib.types; listOf str;
      };
    };
  };
in
{
  options = {
    kompis-os.collabora = lib.mkOption {
      type = lib.types.submodule appOpts;
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts.${cfg.endpoint} =
      let
        proxyPass = "http://127.0.0.1:${toString org.app.${cfg.app}.port}";
      in
      {
        forceSSL = cfg.ssl;
        enableACME = cfg.ssl;

        locations = {
          "^~ /browser" = {
            inherit proxyPass;
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };
          "^~ /hosting/discovery" = {
            inherit proxyPass;
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };
          "^~ /hosting/capabilities" = {
            inherit proxyPass;
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };
          "~ ^/(c|l)ool" = {
            inherit proxyPass;
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };

          "~ ^/cool/(.*)/ws$" = {
            priority = 1;
            inherit proxyPass;
            extraConfig = ''
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
              proxy_set_header Host $host;
              proxy_read_timeout 36000s;
            '';
          };

          "^~ /cool/adminws" = {
            inherit proxyPass;
            extraConfig = ''
              proxy_set_header Host $host;
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
              proxy_read_timeout 36000s;
            '';
          };
        };
      };

    users.users.cool.uid = org.app.${cfg.entity}.id;
    users.groups.cool.gid = org.app.${cfg.entity}.id;

    services.collabora-online = {
      enable = true;
      port = org.app.${cfg.entity}.port;
      aliasGroups = cfg.allowedHosts;

      settings = {
        ssl = {
          enable = false;
          termination = true;
        };
        net = {
          proto = "IPv4";
          listen = "loopback";
        };
      };
    };
  };
}
