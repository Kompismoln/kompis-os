# kompis-os/org.nix
{
  lib,
  lib',
  config,
  ...
}:
let
  cfg = config.flake.org;
  types = {
    host = with lib.types; enum (lib.attrNames cfg.host);
    user = with lib.types; enum (lib.attrNames cfg.user);
    flake = lib.types.attrsOf lib.types.str;
    globalPrefix = lib.types.strMatching "^[0-9a-f]{1,4}:[0-9a-f]{1,4}:[0-9a-f]{1,4}$";
    globalPrefix4 = lib.types.strMatching "^[0-9]{1,3}.[0-9a-f]{1,3}$";
  };
  options = {
    endpoint = lib.mkOption {
      description = "canonical name on internet";
      type = lib.types.str;
    };
    optionalEndpoint = lib.mkOption {
      description = "maybe canonical name on internet";
      default = null;
      type = with lib.types; nullOr str;
    };
    configurationFile = lib.mkOption {
      description = "path to specific configuration";
      type = lib.types.path;
    };
  };
  orgModule = {
    options = {
      inherit (options) endpoint;
      name = lib.mkOption {
        description = "name for organisation";
        type = lib.types.str;
      };
      contact = lib.mkOption {
        description = "contact";
        default = "info@${cfg.domain}";
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
      prefix = lib.mkOption {
        description = "ipv6 private prefix";
        type = types.globalPrefix;
        example = "fda1:b2c3:d4e5";
      };
      prefix4 = lib.mkOption {
        description = "ipv4 private prefix";
        type = types.globalPrefix4;
        example = "10.0";
      };
      build-hosts = lib.mkOption {
        description = "list of designated build hosts";
        default = [ ];
        type = lib.types.listOf types.host;
      };
      namespaces = lib.mkOption {
        description = "namespaces for hosts in the organisation";
        default = [ config.domain ];
        type = with lib.types; listOf str;
      };
      vpn = lib.mkOption {
        description = "attrset of vpn configurations";
        default = { };
        type = lib.types.attrsOf (lib.types.submodule vpnModule);
      };
      mailserver = lib.mkOption {
        description = "main mailserver";
        default = { };
        type = lib.types.submodule mailserverModule;
      };
      flake = lib.mkOption {
        description = "flake for this organisation";
        default = { };
        type = with lib.types; attrsOf str;
      };
      domain = lib.mkOption {
        description = "domains managed by organisation";
        default = { };
        type = lib.types.attrsOf (lib.types.submodule domainModule);
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
        type = with lib.types; attrsOf (attrsOf (listOf str));
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
        type = lib.types.attrsOf (lib.types.submodule hostModule);
      };
      user = lib.mkOption {
        description = "record of all users";
        type = lib.types.attrsOf (lib.types.submodule userModule);
      };
      service = lib.mkOption {
        description = "record of all services";
        type = lib.types.attrsOf (lib.types.submodule serviceModule);
      };
      app = lib.mkOption {
        description = "record of all apps";
        type = lib.types.attrsOf (lib.types.submodule appModule);
      };
      theme = lib.mkOption {
        description = "colors, wallpaper and fonts";
        type = lib.types.submodule themeModule;
      };
      ids = lib.mkOption {
        description = "id mappings";
        type = with lib.types; attrsOf number;
      };
    };
  };
  themeModule = {
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
  appModule =
    { name, config, ... }:
    {
      options = {
        inherit (options) endpoint;
        name = lib.mkOption {
          description = "app name";
          default = name;
          type = lib.types.str;
        };
        configurationFile = options.configurationFile // {
          default = ../apps/${config.name}.nix;
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
  serviceModule = {
    options = {
      endpoint = options.optionalEndpoint;
      data = lib.mkOption {
        description = "arbitrary data to service";
        type = with lib.types; attrsOf anything;
      };
      grants = lib.mkOption {
        type = with lib.types; listOf str;
      };
    };
  };
  userModule = {
    options = {
      mail = lib.mkEnableOption "internal mail";
      description = lib.mkOption {
        description = "full name";
        type = lib.types.str;
      };
      email = lib.mkOption {
        description = "user's email address";
        default = null;
        type = with lib.types; nullOr str;
      };
      grants = lib.mkOption {
        type = with lib.types; listOf str;
      };
      inboxes = lib.mkOption {
        type = with lib.types; listOf str;
      };
    };
  };
  vpnModule =
    { name, config, ... }:
    let
      vpn = config;
    in
    {
      options = {
        enable = lib.mkEnableOption "a wireguard vpn" // {
          default = true;
        };
        id = lib.mkOption {
          description = "unique integer identifier for the vpn";
          type = lib.types.int;
        };
        name = lib.mkOption {
          description = "name of the vpn";
          type = lib.types.str;
          default = name;
        };
        trusted = lib.mkOption {
          description = "disable firewalls on this vpn";
          type = lib.types.bool;
        };
        address4 = lib.mkOption {
          description = "ipv4 vpn address";
          type = lib.types.str;
          default = "${vpn.prefix4}.0/${toString vpn.prefix4-length}";
        };
        prefix4 = lib.mkOption {
          description = "ipv4 prefix for peers in vpn";
          type = lib.types.str;
          default = "${cfg.prefix4}.${toString vpn.id}";
        };
        prefix4-length = lib.mkOption {
          description = "ipv4 prefix length for peers in vpn";
          type = lib.types.int;
          default = 24;
        };
        address = lib.mkOption {
          description = "ipv6 vpn address";
          type = lib.types.str;
          default = "${vpn.prefix}::/${toString vpn.prefix-length}";
        };
        addressWithBrackets = lib.mkOption {
          description = "ipv6 vpn address enclosed in square brackets";
          type = lib.types.str;
          readOnly = true;
          default = "[${vpn.prefix}::]/${toString vpn.prefix-length}";
        };
        prefix = lib.mkOption {
          description = "ipv6 prefix for peers in vpn";
          type = lib.types.str;
          default = "${cfg.prefix}:${lib'.hex vpn.id}";
        };
        prefix-length = lib.mkOption {
          description = "ipv6 prefix length for peers in vpn";
          type = lib.types.int;
          default = 64;
        };
        interface = lib.mkOption {
          description = "interface for the vpn";
          type = lib.types.str;
          default = name;
        };
        namespace = lib.mkOption {
          description = "top domain in the vpns";
          type = lib.types.str;
        };
        port = lib.mkOption {
          description = "port allocated for the vpn";
          type = lib.types.port;
          default = 51820 + vpn.id;
        };
        keepalive = lib.mkOption {
          description = "port allocated for the vpn";
          default = 25;
          type = lib.types.number;
        };
        gateway = lib.mkOption {
          description = "designated gateway host";
          type = lib.types.str;
        };
        proxy = lib.mkEnableOption "ipv6 proxy through gateway";
        dns = lib.mkOption {
          description = "list of name servers";
          type = with lib.types; listOf str;
        };
        resetOnRebuild = lib.mkOption {
          description = "destroy and recreate network device post rebuild";
          type = lib.types.bool;
          default = true;
        };
        allowedTCPPorts = lib.mkOption {
          description = "force all peers to allow these tcp ports in the vpn";
          default = [ ];
          type = with lib.types; listOf anything;
        };
        allowedUDPPorts = lib.mkOption {
          description = "force all peers to allow these udp ports in the vpn";
          default = [ ];
          type = with lib.types; listOf anything;
        };
      };
    };

  mailserverModule = {
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

  domainModule =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          description = "domain name";
          type = lib.types.str;
          default = name;
        };
        mailbox = lib.mkEnableOption "mailbox";
      };
    };

  hostModule =
    { name, config, ... }:
    let
      host = config;
    in
    {
      options = {
        configurationFile = options.configurationFile // {
          default = ../hosts/${host.name}/configuration.nix;
        };
        name = lib.mkOption {
          description = "hostname";
          type = lib.types.str;
          default = name;
        };
        hardwareReport = lib.mkOption {
          description = "hardware report method";
          type = lib.types.enum [
            "standard"
            "facter"
          ];
          default = "facter";
        };
        facterFile = lib.mkOption {
          description = "facter report path";
          default = ../hosts/${host.name}/facter.json;
          type = lib.types.path;
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
        endpoint = options.optionalEndpoint;
        vpns = lib.mkOption {
          description = "list of interface names for vpns";
          type = with lib.types; listOf str;
        };
        system = lib.mkOption {
          description = "host platform";
          type = lib.types.str;
        };
        stateVersion = lib.mkOption {
          description = "nixos state version";
          type = with lib.types; nullOr str;
          default = null;
        };
        home = lib.mkOption {
          description = "list of home configurations for a user";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule ({ name, ... }: homeModule { inherit name host; }));
        };
        network = lib.mkOption {
          description = "networks to configure on host";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule networkModule);
        };
        disk-layouts = lib.mkOption {
          description = "record of disk layouts that applies to host";
          default = { };
          type = lib.types.attrsOf lib.types.anything;
        };
        desktop = lib.mkOption {
          description = "attrset of desktop settings";
          default = { };
          type = lib.types.attrsOf lib.types.anything;
        };
        monitors = lib.mkOption {
          description = "list of monitors possibly connected to the host";
          default = [ ];
          type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
        };
        devices = lib.mkOption {
          description = "list of devices possibly connected to the host";
          default = [ ];
          type = lib.types.listOf (lib.types.attrsOf lib.types.anything);
        };
      };
      config.network = lib.mapAttrs (
        vpnName: vpn:
        lib.mkDefault {
          inherit (vpn) interface;
          mode = "static";
          dns = lib.concatMap (dnsHost: [
            cfg.host.${dnsHost}.network.${vpnName}.address
            cfg.host.${dnsHost}.network.${vpnName}.address4
          ]) vpn.dns;
          address = "${vpn.prefix}::${lib'.hex host.id}";
          address4 = "${vpn.prefix4}.${toString host.id}";
        }
      ) cfg.vpn;
    };

  homeModule =
    { name, host, ... }:
    {
      options = {
        configurationFile = options.configurationFile // {
          default = ../homes + "/${name}@${host.name}.nix";
        };
        roles = lib.mkOption {
          type = with lib.types; listOf str;
        };
      };
    };

  networkModule =
    { name, ... }:
    {
      options = {
        type = lib.mkOption {
          description = "network type";
          default = name;
          type = lib.types.str;
        };
        interface = lib.mkOption {
          description = "interface associated with the network";
          type = lib.types.str;
        };
        mode = lib.mkOption {
          type = lib.types.enum [
            "dhcp"
            "static"
          ];
          default = "dhcp";
        };
        dns = lib.mkOption {
          type = with lib.types; listOf str;
        };
        gateway = lib.mkOption {
          description = "ipv6 gateway address";
          type = with lib.types; nullOr str;
          default = null;
        };
        address = lib.mkOption {
          description = "ipv6 host address";
          type = with lib.types; nullOr str;
          default = null;
        };
        address4 = lib.mkOption {
          description = "ipv4 host address";
          type = with lib.types; nullOr str;
          default = null;
        };
        gateway4 = lib.mkOption {
          description = "ipv4 gateway address";
          type = with lib.types; nullOr str;
          default = null;
        };
        metric = lib.mkOption {
          description = "metric for routing: lower takes priority";
          default = 1024;
          type = lib.types.number;
        };
      };
    };

in
{
  options.flake.org = lib.mkOption {
    description = "org.toml";
    type = lib.types.submodule orgModule;
    default = throw "org.toml not loaded";
  };
}
