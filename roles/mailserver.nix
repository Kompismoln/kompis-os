{ org, lib, ... }:
{
  imports = [
    ../modules/mailserver.nix
  ];
  kompis-os.mailserver = {
    enable = true;
    domain = org.domain;
    dkimSelector = "k1";

    users.admin = {
      aliases = org.inboxes;
    };

    users.alex = {
      aliases = org.user.alex.inboxes;
    };

    domains = lib.mapAttrs (_: siteCfg: {
      mailbox = siteCfg.mailbox;
    }) org.site;
  };
}
