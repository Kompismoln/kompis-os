{
  org,
  ...
}:
let
  name = "nextcloud-kompismoln";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/mysql.nix
    ../kompis-os/nixos/nextcloud.nix
    ../kompis-os/nixos/nginx.nix
    ../kompis-os/nixos/postgresql.nix
  ];

  nextcloud.sites.${name} = {
    enable = true;
    hostname = cfg.endpoint;
    collaboraHost = org.app.collabora.endpoint;
  };
}
