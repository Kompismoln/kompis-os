# kompis-os/apps/klimatkalendern-dev.nix
{ org, pkgs, ... }:
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
    postgresql.enable = true;
    mobilizon.apps.${name} = {
      enable = true;
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
