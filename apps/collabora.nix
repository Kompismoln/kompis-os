# apps/collabora.nix
{ app, ... }:
{
  imports = [
    ../kompis-os/nixos/collabora.nix
  ];

  kompis-os = {
    collabora = {
      enable = true;
      inherit (app) endpoint;
      inherit (app.principal) bindAddress;
      allowedHosts = [ ];
    };
  };
}
