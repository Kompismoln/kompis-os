# kompis-os/apps/klimatkalendern.nix
{ org, ... }:
let
  name = "klimatkalendern";
  appCfg = org.app.${name};
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
      inherit (appCfg) endpoint;
    };
  };
}
