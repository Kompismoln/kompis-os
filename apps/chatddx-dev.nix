# kompis-os/apps/chatddx-dev.nix
{
  org,
  inputs,
  ...
}:
let
  name = "chatddx-dev";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/django.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  services.nginx.virtualHosts.${cfg.endpoint} = {
    root = inputs.swift-dev.packages."x86_64-linux".default;

    locations."/" = {
      tryFiles = "$uri $uri/ =404";
    };

    forceSSL = true;
    enableACME = true;
  };

  kompis-os = {
    nginx.enable = true;
    postgresql.enable = true;
    users.${name}.class = "app";

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
