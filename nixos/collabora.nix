{
  config,
  lib,
  ...
}:
let
  app = config.kompis-os.collabora;
  appOpts = {
    options = {
      enable = lib.mkEnableOption "nextcloud";
      endpoint = lib.mkOption {
        description = "app's endpoint";
        type = lib.types.str;
      };
      bindAddress = lib.mkOption {
        description = "address this app should bind to";
        type = lib.types.str;
      };
      allowedHosts = lib.mkOption {
        description = "Accept WOPI from these hosts";
        type = with lib.types; listOf str;
      };
      port = lib.mkOption {
        description = "port";
        type = lib.types.port;
        default = 9980;
      };
      ssl = lib.mkOption {
        description = "force encrypted connections";
        type = lib.types.bool;
        default = true;
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

  config = lib.mkIf app.enable {
    services.nginx.virtualHosts.${app.endpoint} =
      let
        proxyPass = "http://[${app.bindAddress}]:${toString app.port}";
      in
      {
        forceSSL = app.ssl;
        enableACME = app.ssl;

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

    services.collabora-online = {
      enable = true;
      inherit (app) port;
      aliasGroups = app.allowedHosts;

      settings = {
        ssl = {
          enable = false;
          termination = true;
        };
        net = {
          proto = "IPv6";
          listen = app.bindAddress;
        };
      };
    };
  };
}
