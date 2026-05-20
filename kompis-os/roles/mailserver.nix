# kompis-os/roles/mailserver.nix
{
  flake.nixosModules.mailserver =
    { org, lib, ... }:
    {
      imports = [
        ../nixos/mailserver.nix
      ];
      kompis-os.mailserver = {
        enable = true;
        inherit (org) domain;
        inherit (org.mailserver) dkimSelector;

        users = lib.mapAttrs (user: _: { aliases = org.user.${user}.inboxes; }) (
          lib.filterAttrs (_: userCfg: lib.hasAttr "mail" userCfg && userCfg.mail) org.user
        );

        domains = lib.mapAttrs (_: siteCfg: {
          inherit (siteCfg) mailbox;
        }) org.dns;
      };
    };
}
