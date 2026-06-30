# kompis-os/apps/chatddx.nix
{
  config,
  org,
  inputs,
  ...
}:
let
  name = "chatddx";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/django.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  services.nginx.virtualHosts.${cfg.endpoint} = {
    root = inputs.swift.packages."x86_64-linux".default;

    locations."/" = {
      tryFiles = "$uri $uri/ =404";
    };

    forceSSL = true;
    enableACME = true;
  };

  kompis-os = {
    users.${name}.class = "app";

    nginx.enable = true;

    postgresql.databases.${name} = {
      enable = true;
      dumpPath = "${config.kompis-os.django.apps."${name}-django".home}/dbdump.sql";
    };

    django.apps."${name}-django" = {
      enable = true;
      entity = name;
      inherit (cfg) endpoint;
      djangoApp = "chatddx.django";
      locationProxy = "~ ^/(admin|api)";
      trustedOrigins = [ "https://${cfg.endpoint}" ];
      timeout = 180;
    };
  };
}
