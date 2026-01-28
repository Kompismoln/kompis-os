# apps/opencloud-kompismoln.nix
{
  org,
  ...
}:
let
  name = "opencloud-kompismoln";
  cfg = org.app.${name};
in
{
  imports = [
    ../kompis-os/nixos/opencloud.nix
  ];

  kompis-os = {
    nginx.enable = true;
    users.${name} = {
      class = "app";
      members = [
        "nginx"
      ];
    };
    opencloud.apps.${name} = {
      enable = true;
      user = name;
      inherit (cfg) endpoint;
    };
  };
}
