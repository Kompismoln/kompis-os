# apps/nextcloud-kompismoln-dev.nix
{
  org,
  ...
}:
let
  name = "nextcloud-kompismoln-dev";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/collabora.nix
    ../kompis-os/nixos/nextcloud.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  kompis-os = {
    postgresql.enable = true;
    nginx.enable = true;
    users.${name} = {
      class = "app";
      members = [
        "nginx"
      ];
    };
    nextcloud.apps.${name} = {
      enable = true;
      user = name;
      inherit (cfg) endpoint;
      collabora.endpoint = org.app.collabora-dev.endpoint;
    };
  };
}
