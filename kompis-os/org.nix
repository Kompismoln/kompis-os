# kompis-os/org.nix
{ lib, ... }:
let
  orgOpts =
    { name, config, ... }:
    let
      orgCfg = config;
    in
    {
      options = {
        name = lib.mkOption {
          description = "name for organisation";
          type = lib.types.str;
        };
        domain = lib.mkOption {
          description = "domain name for organisation";
          type = lib.types.str;
        };
        contact = lib.mkOption {
          description = "contact";
          default = "info@${config.domain}";
          type = lib.types.str;
        };
        timezone = lib.mkOption {
          description = "timezone";
          example = "Europe/Stockholm";
          type = lib.types.str;
        };
        locale = lib.mkOption {
          description = "default locale";
          type = lib.types.str;
          example = "en_US.UTF-8";
        };
        host-config = lib.mkOption {
          description = "path template for host specific configuration";
          default = "hosts/$host/configuration.nix";
          type = lib.types.str;
        };
        home-config = lib.mkOption {
          description = "path template for home specific configuration";
          default = "homes/$home.nix";
          type = lib.types.str;
        };
        app-config = lib.mkOption {
          description = "path template for app specific configuration";
          default = "apps/$appp.nix";
          type = lib.types.str;
        };
        build-hosts = lib.mkOption {
          description = "list of designated build hosts";
          default = "apps/$appp.nix";
          type = with lib.types; listOf str;
        };
        namespaces = lib.mkOption {
          description = "namespaces for hosts in the organisation";
          default = [ config.domain ];
          type = with lib.types; listOf str;
        };
        subnet = lib.mkOption {
          description = "attrset of subnet configurations";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule subnetOpts);
        };
        mailserver = lib.mkOption {
          description = "main mailserver";
          default = { };
          type = lib.types.submodule mailserverOpts;
        };
        flake = lib.mkOption {
          description = "flake for this organisation";
          default = { };
          type = with lib.types; attrsOf str;
        };
        dns = lib.mkOption {
          description = "domains managed by organisation";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule dnsOpts);
        };
        public-artifacts = lib.mkOption {
          description = "path templates for public artifacts";
          type = with lib.types; attrsOf str;
        };
        secrets = lib.mkOption {
          description = "path templates for secrets";
          type = with lib.types; attrsOf str;
        };
        class = lib.mkOption {
          description = "metadata for classes";
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                keys = lib.mkOption {
                  type = with lib.types; listOf str;
                };
              };
            }
          );
        };
        ops = lib.mkOption {
          description = "operations per entity groups";
          type = with lib.types; attrsOf listOf str;
        };
        root-identities = lib.mkOption {
          description = "list of root identities";
          default = "apps/$appp.nix";
          type = with lib.types; listOf str;
        };
        root = lib.mkOption {
          description = "attrs of root identities";
          type = lib.types.attrsOf lib.types.anything;
          default = { };
        };
        host = lib.mkOption {
          description = "record of all hosts";
          type = lib.types.attrsOf (lib.types.submodule hostOpts);
        };
        user = lib.mkOption {
          description = "record of all users";
          type = lib.types.attrsOf (lib.types.submodule userOpts);
        };
        service = lib.mkOption {
          description = "record of all services";
          type = lib.types.attrsOf (lib.types.submodule serviceOpts);
        };
        app = lib.mkOption {
          description = "record of all apps";
          type = lib.types.attrsOf (lib.types.submodule appOpts);
        };
        theme = lib.mkOption {
          description = "colors, wallpaper and fonts";
          type = lib.types.submodule themeOpts;
        };
        ids = lib.mkOption {
          description = "id mappings";
          type = with lib.types; attrsOf number;
        };
      };
    };
  themeOpts = {
    options = {
      wallpaper = lib.mkOption {
        description = "path to wallpaper";
        type = lib.types.str;
      };
      colors = lib.mkOption {
        description = "color mappings";
        type = with lib.types; attrsOf str;
      };
      fonts = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.submodule {
            options = {
              package = lib.mkOption {
                description = "font package";
                type = lib.types.str;
              };
              name = lib.mkOption {
                description = "font name";
                type = lib.types.str;
              };
            };
          }
        );
      };
    };
  };
  appOpts = {
    options = {
      endpoint = lib.mkOption {
        description = "canonical name on internet";
        type = lib.types.str;
      };
      altpoints = lib.mkOption {
        description = "alternative access points that should be redirected to endpoint";
        default = [ ];
        type = with lib.types; listOf str;
      };
      run-on-hosts = lib.mkOption {
        description = "hosts that this app should run on";
        type = with lib.types; listOf str;
      };
      grants = lib.mkOption {
        type = with lib.types; listOf str;
      };
    };
  };
  serviceOpts = {
    options = {
      endpoint = lib.mkOption {
        description = "canonical name on internet";
        type = lib.types.str;
      };
      data = lib.mkOption {
        description = "arbitrary data to service";
        type = with lib.types; attrsOf anything;
      };
      grants = lib.mkOption {
        type = with lib.types; listOf str;
      };
    };
  };
  userOpts = {
    options = {
      mail = lib.mkEnableOption "internal mail";
      description = lib.mkOption {
        description = "full name";
        type = lib.types.str;
      };
      email = lib.mkOption {
        description = "user's email address";
        type = lib.types.str;
      };
      grants = lib.mkOption {
        type = with lib.types; listOf str;
      };
      inboxes = lib.mkOption {
        type = with lib.types; listOf str;
      };
    };
  };
  subnetOpts = {
    options = {
      enable = lib.mkEnableOption "a wireguard subnet";
      address = lib.mkOption {
        description = "CIDR for the subnet";
        type = lib.types.str;
      };
      namespace = lib.mkOption {
        description = "top domain in the subnets";
        type = lib.types.str;
      };
      port = lib.mkOption {
        description = "port allocated for the subnet";
        type = lib.types.port;
      };
      keepalive = lib.mkOption {
        description = "port allocated for the subnet";
        type = lib.types.number;
      };
      gateway = lib.mkOption {
        description = "designated gateway host";
        type = lib.types.str;
      };
      dns = lib.mkOption {
        description = "list of name servers";
        type = with lib.types; listOf str;
      };
      resetOnRebuild = lib.mkOption {
        description = "destroy and recreate network device post rebuild";
        type = lib.types.bool;
      };
      peerAddress = lib.mkOption {
        description = "template for peer addresses (hack)";
        example = "10.0.0.x";
        type = lib.types.str;
      };
      allowedTCPPortRanges = lib.mkOption {
        description = "user's entity class";
        default = [ ];
        type = with lib.types; listOf anything;
      };
    };
  };

  mailserverOpts = {
    options = {
      dkimSelector = lib.mkOption {
        description = "dkim selector";
        type = lib.types.str;
      };
      host = lib.mkOption {
        description = "host";
        type = lib.types.str;
      };
      int = lib.mkOption {
        description = "internal name";
        type = lib.types.str;
      };
      ext = lib.mkOption {
        description = "external name";
        type = lib.types.str;
      };
    };
  };

  dnsOpts = {
    options = {
      mailbox = lib.mkEnableOption "mailbox";
    };
  };

  hostOpts = {
    options = {
      facter = lib.mkOption {
        description = "use this facter.json instead of hardware-configuration";
        default = null;
        type = with lib.types; nullOr str;
      };
      id = lib.mkOption {
        description = "internal host id";
        type = lib.types.number;
      };
      users = lib.mkOption {
        description = "users";
        type = with lib.types; listOf str;
      };
      roles = lib.mkOption {
        description = "roles that this host has";
        type = with lib.types; listOf str;
      };
      endpoint = lib.mkOption {
        description = "external access point";
        default = null;
        type = lib.types.str;
      };
      dnsFor = lib.mkOption {
        description = "subnet this host is dns for";
        type = lib.types.str;
      };
      subnets = lib.mkOption {
        description = "list of interface names for subnets";
        type = with lib.types; listOf str;
      };
      system = lib.mkOption {
        description = "host platform";
        type = lib.types.str;
      };
      stateVersion = lib.mkOption {
        description = "nixos state version";
        type = lib.types.str;
      };
      homes = lib.mkOption {
        description = "list of home configurations for a user";
        default = { };
        type = lib.types.attrsOf (lib.types.submodule homeOpts);
      };
      disk-layouts = lib.mkOption {
        description = "record of disk layouts that applies to host";
        default = { };
        type = lib.types.attrsOf lib.types.anything;
      };
      desktop = lib.mkOption {
        description = "list of desktop settings";
        default = { };
        type = lib.types.attrsOf (lib.types.anything);
      };
      monitors = lib.mkOption {
        description = "list of monitors possibly connected to the host";
        default = { };
        type = lib.types.listOf (lib.types.attrsOf (lib.types.anything));
      };
      devices = lib.mkOption {
        description = "list of devices possibly connected to the host";
        default = { };
        type = lib.types.listOf (lib.types.attrsOf (lib.types.anything));
      };
    };
  };

  homeOpts.options = {
    roles = lib.mkOption {
      type = with lib.types; listOf str;
    };
  };

in
{
  options.flake.org = lib.mkOption {
    description = "org.toml";
    type = lib.types.submodule orgOpts;
    default = throw "org.toml not loaded";
  };
}
