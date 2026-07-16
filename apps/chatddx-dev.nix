# kompis-os/apps/chatddx-dev.nix
{
  app,
  inputs,
  config,
  host,
  ...
}:
{
  imports = [
    ../kompis-os/nixos/django.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  services.nginx.virtualHosts.${app.endpoint} = {
    root = inputs.swift-dev.packages."x86_64-linux".default;

    locations."/" = {
      tryFiles = "$uri $uri/ =404";
    };

    forceSSL = true;
    enableACME = true;
  };

  sops.secrets."${app.name}/secret-key" = {
    inherit (app.secrets) sopsFile;
    owner = app.name;
    group = app.name;
  };

  kompis-os = {
    nginx.enable = true;

    postgresql.databases.${app.name} = {
      enable = true;
      dumpPath = "${app.principal.home}/dbdump.sql";
    };

    django.apps.${app.name} = {
      inherit (app) name endpoint;
      inherit (app.principal) bindAddress;
      enable = true;
      home = "${app.principal.home}/django";
      package = inputs.${app.name}.packages.${host.system}.django-app;
      secretKeyPath = config.sops.secrets."${app.name}/secret-key".path;
      scripts = inputs.${app.name}.packages.${host.system}.scripts;
      module = "chatddx.django";
      database = app.name;
      user = app.name;
      locationProxy = "~ ^/(admin|api)";
      trustedOrigins = [ "https://${app.endpoint}" ];
      timeout = 180;
    };
  };
}
