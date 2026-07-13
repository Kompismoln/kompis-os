# nixos/org/users.nix
{
  org,
  host,
  lib,
  ...
}:
{
  imports = [
    ../principals.nix
  ];
  kompis-os = {
    principals = lib.listToAttrs (
      map (
        user:
        lib.nameValuePair user {
          inherit (org.user.${user}) description groups;
        }
      ) host.users
    );
  };
}
