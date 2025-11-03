# kompis-os/nixos/mailserver.nix
{
  config,
  inputs,
  lib,
  lib',
  org,
  ...
}:

let
  cfg = config.kompis-os.mailserver;
  relayDomains = lib.filterAttrs (domain: cfg: !cfg.mailbox) cfg.domains;
  mailboxDomains = lib.filterAttrs (domain: cfg: cfg.mailbox) cfg.domains;
in
{
  imports = [
    inputs.nixos-mailserver.nixosModules.default
  ];

  options.kompis-os.mailserver = {
    enable = lib.mkEnableOption "mailserver on this host";
    domain = lib.mkOption {
      description = "The domain name of this mailserver.";
      type = lib.types.str;
    };
    dkimSelector = lib.mkOption {
      description = "Label for the DKIM key currently in use.";
      type = lib.types.str;
    };
    users = lib.mkOption {
      description = "Configure user accounts.";
      type = lib.types.attrsOf (
        lib.types.submodule (
          { name, ... }:
          {
            options = {
              enable = (lib.mkEnableOption "this user") // {
                default = true;
              };
              email = lib.mkOption {
                description = "User email";
                type = lib.types.str;
                default = "${name}@${org.domain}";
              };
              catchAll = lib.mkOption {
                description = "Make the user recipient of a whole domain.";
                type = with lib.types; listOf str;
                default = [ ];
              };
              aliases = lib.mkOption {
                description = "Make the user recipient of alternative emails";
                type = with lib.types; listOf str;
                default = [ ];
              };
            };
          }
        )
      );
    };
    domains = lib.mkOption {
      description = "List of domains to manage.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            mailbox = lib.mkOption {
              description = "Enable if this host is the domain's final destination.";
              type = lib.types.bool;
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {

      kompis-os.preserve.directories = with config.mailserver; [
        dkimKeyDirectory
        mailDirectory
        sieveDirectory
      ];

      preservation.preserveAt."/srv/database" = {
        directories = [
          {
            directory = "/var/lib/rspamd";
            user = "rspamd";
            group = "rspamd";
          }
        ];
      };

      sops.secrets =
        lib'.mergeAttrs (user: _: {
          "${user}/mail-sha512" = {
            sopsFile = lib'.secrets "user" user;
            restartUnits = [
              "dovecot2.service"
              "postfix.service"
            ];
          };
        }) cfg.users
        // {
          "dmarc-reports/mail-sha512" = {
            sopsFile = lib'.secrets "service" "dmarc-reports";
            restartUnits = [
              "dovecot2.service"
              "postfix.service"
            ];
          };
        };

      mailserver = {
        enable = true;
        stateVersion = 3;
        fqdn = "mail.${cfg.domain}";
        dkimSelector = cfg.dkimSelector;
        domains = lib.mapAttrsToList (domain: _: domain) mailboxDomains;
        domainsWithoutMailbox = lib.mapAttrsToList (domain: _: domain) relayDomains;
        enableSubmissionSsl = false;
        mailboxes = {
          Drafts = {
            auto = "subscribe";
            specialUse = "Drafts";
          };
          Junk = {
            auto = "subscribe";
            specialUse = "Junk";
          };
          Sent = {
            auto = "subscribe";
            specialUse = "Sent";
          };
          Trash = {
            auto = "subscribe";
            specialUse = "Trash";
          };
          Archive = {
            auto = "subscribe";
            specialUse = "Archive";
          };
        };

        loginAccounts = lib.mkMerge [
          (lib.mapAttrs' (user: userCfg: {
            name = userCfg.email;
            value = {
              inherit (userCfg) catchAll aliases;
              hashedPasswordFile = config.sops.secrets."${user}/mail-sha512".path;
            };
          }) cfg.users)
          {
            "dmarc-reports@${cfg.domain}" = {
              hashedPasswordFile = config.sops.secrets."dmarc-reports/mail-sha512".path;
              catchAll = [ ];
              aliases = [ ];
            };
          }
        ];

        certificateScheme = "acme-nginx";
      };

      services = {

        #fail2ban.jails = {
        #  postfix.settings = {
        #    filter = "postfix[mode=aggressive]";
        #  };
        #  dovecot.settings = {
        #    filter = "dovecot[mode=aggressive]";
        #  };
        #};

        postfix = {
          settings.main = {
            myorigin = cfg.domain;
            mynetworks = [
              "127.0.0.1/32"
              "[::1]/128"
            ]
            ++ (lib.mapAttrsToList (iface: ifaceCfg: ifaceCfg.address) org.subnet);
          };
          transport =
            let
              transportsList = lib.mapAttrsToList (domain: cfg: "${domain} smtp:") relayDomains;
              transportsCfg = lib.concatStringsSep "\n" transportsList;
            in
            transportsCfg;
        };
      };
    })
  ];
}
