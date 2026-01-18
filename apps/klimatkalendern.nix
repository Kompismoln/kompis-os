# kompis-os/apps/klimatkalendern.nix
{
  config,
  org,
  ...
}:
let
  name = "klimatkalendern";
  app = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/mobilizon.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  kompis-os = {
    nginx.enable = true;
    postgresql.databases.${name} = {
      enable = true;
      dumpPath = "${config.users.users.${name}.home}/dbdump.sql";
    };

    users.${name}.class = "app";

    mobilizon.apps.${name} = {
      enable = true;
      migration = "20250919143627";
      inherit (app) endpoint;
    };
  };
}
