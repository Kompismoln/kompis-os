# nixos/org/principals.nix
{
  config,
  lib,
  pkgs,
  host,
  ...
}:
let
  principals = lib.filterAttrs (
    _: entity: entity.principal != null && entity.id != null
  ) host.entities;
in
{
  imports = [
    ../preserve.nix
  ];

  sops.secrets = lib.mapAttrs' (
    _: entity:
    lib.nameValuePair "${entity.name}/passwd-sha512" {
      neededForUsers = true;
      inherit (entity.secrets) sopsFile;
    }
  ) (lib.filterAttrs (_: entity: entity.principal.hasPasswd) principals);

  users = {
    mutableUsers = false;
    users = lib.mapAttrs' (
      _: entity:
      lib.nameValuePair entity.name (
        let
          isNormalUser = entity.class == "user";
          publicKey = entity.public-artifacts.ssh-key;
          passwordFile = config.sops.secrets."${entity.name}/passwd-sha512".path;
        in
        rec {
          inherit (entity.principal)
            home
            homeMode
            uid
            ;
          inherit (entity) description;
          inherit isNormalUser;
          isSystemUser = !isNormalUser;
          group = entity.name;
          extraGroups = entity.principal.groups;
          openssh.authorizedKeys.keyFiles = lib.mkIf entity.principal.hasPublicKey [ publicKey ];
          hashedPasswordFile = lib.mkIf entity.principal.hasPasswd passwordFile;
          shell = lib.mkIf entity.principal.hasBash pkgs.bash;
          createHome = home != "/var/empty";
        }
      )
    ) principals;

    groups = lib.mapAttrs' (
      _: entity:
      lib.nameValuePair entity.name {
        inherit (entity.principal) gid;
        members = [ entity.name ] ++ entity.principal.members;
      }
    ) principals;
  };

  kompis-os.preserve.directories = map (entity: {
    directory = entity.principal.home;
    user = entity.name;
    group = entity.name;
  }) (builtins.filter (entity: entity.principal.home != "/var/empty") (lib.attrValues principals));
}
