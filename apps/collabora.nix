# apps/collabora.nix
{ org, ... }:
let
  name = "collabora";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/collabora.nix
  ];

  kompis-os = {
    collabora = {
      app = name;
      enable = true;
      endpoint = cfg.endpoint;
      allowedHosts = [ ];
    };
  };
}
