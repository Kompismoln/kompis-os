# kompis-os/apps/klimatkalendern-dev.nix
{
  app,
  pkgs,
  inputs,
  host,
  ...
}:
{
  imports = [
    ../kompis-os/nixos/mobilizon.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  kompis-os = {
    nginx.enable = true;
    postgresql.databases.${app.database} = {
      enable = true;
      dumpPath = "${app.principal.home}/dbdump.sql";
    };

    mobilizon.apps.${app.name} = {
      enable = true;
      inherit (app) endpoint name;
      inherit (app.principal) bindAddress uid gid;
      home = "${app.principal.home}/mobilizon";
      package = inputs.${app.name}.packages.${host.system}.default;
      database = app.name;
      user = app.name;
    };
  };
  services.mobilizon.settings."Mobilizon.Web.Email.Mailer" =
    let
      inherit ((pkgs.formats.elixirConf { }).lib) mkAtom;
    in
    {
      adapter = mkAtom "Swoosh.Adapters.SMTP";
      relay = "helsinki.km";
    };
}
