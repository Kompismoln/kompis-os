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
        domain = org.domain;
        dkimSelector = org.mailserver.dkimSelector;

        users = lib.mapAttrs (user: userCfg: { aliases = org.user.${user}.inboxes; }) (
          lib.filterAttrs (user: userCfg: lib.hasAttr "mail" userCfg && userCfg.mail) org.user
        );

        domains = lib.mapAttrs (_: siteCfg: {
          mailbox = siteCfg.mailbox;
        }) org.dns;
      };
    };
}
