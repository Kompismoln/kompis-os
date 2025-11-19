# kompis-os/apps/klimatkalendern-dev.nix
{
  config,
  org,
  pkgs,
  ...
}:
let
  name = "klimatkalendern-dev";
  cfg = org.app.${name};
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

    users.${name} = {
      class = "app";
    };

    mobilizon.apps.${name} = {
      enable = true;
      migration = "20250919143627";
      inherit (cfg) endpoint;
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
