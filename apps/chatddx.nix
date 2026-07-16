# kompis-os/apps/chatddx.nix
{
  app,
  inputs,
  ...
}:
{
  imports = [
    ../kompis-os/nixos/django.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  services.nginx.virtualHosts.${app.endpoint} = {
    root = inputs.swift.packages."x86_64-linux".default;

    locations."/" = {
      tryFiles = "$uri $uri/ =404";
    };

    forceSSL = true;
    enableACME = true;
  };

  kompis-os = {
    nginx.enable = true;

    postgresql.databases.${app.name} = {
      enable = true;
      dumpPath = "${app.principal.home}/dbdump.sql";
    };

    django.apps."${app.name}-django" = {
      enable = true;
      entity = app;
      module = "chatddx.django";
      locationProxy = "~ ^/(admin|api)";
      trustedOrigins = [ "https://${app.endpoint}" ];
      timeout = 180;
    };
  };
}
