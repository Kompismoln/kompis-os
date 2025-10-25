{
  lib,
  lib',
  config,
  ...
}:
let
  cfg = config.kompis-os.collabora;
in
{
  options = {
    kompis-os.collabora = {
      enable = lib.mkEnableOption "collabora-online on this server";
      subnet = lib.mkOption {
        description = "Use self-signed certificates";
        default = false;
        type = lib.types.bool;
      };
      host = lib.mkOption {
        description = "Public hostname";
        type = lib.types.str;
      };
      allowedHosts = lib.mkOption {
        description = "Accept WOPI from these hosts";
        type = with lib.types; listOf str;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    services.nginx.virtualHosts.${cfg.host} =
      let
        proxyPass = "http://127.0.0.1:${builtins.toString lib'.ids.collabora.port}";
      in
      {
        forceSSL = true;
        sslCertificate = lib.mkIf cfg.subnet ../domains/km-tls-cert.pem;
        sslCertificateKey = lib.mkIf cfg.subnet config.sops.secrets."km/tls-cert".path;

        enableACME = !cfg.subnet;

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
      port = lib'.ids.collabora.port;
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
