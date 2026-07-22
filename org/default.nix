# org/default.nix
{
  lib,
  config,
  ...
}:
let
  orgFlake = config;
  inherit (config) org;

  types = import ./types.nix {
    inherit lib org;
  };
  factories = import ./factories.nix {
    inherit lib org;
  };

  orgModule = {
    options = {
      inventoryRoot = lib.mkOption {
        description = "path to inventory";
        type = lib.types.path;
        default = orgFlake.path;
      };
      endpoint = lib.mkOption {
        description = "canonical name on internet";
        type = lib.types.str;
      };
      name = lib.mkOption {
        description = "name for organisation";
        type = lib.types.str;
      };
      contact = lib.mkOption {
        description = "contact";
        default = "info@${org.endpoint}";
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
        type = types.globalPrefix6;
        example = "fda1:b2c3:d4e5";
      };
      prefixLength = lib.mkOption {
        description = "ipv6 private prefix length";
        type = lib.types.int;
        default = 64;
      };
      prefix4 = lib.mkOption {
        description = "ipv4 private prefix";
        type = types.globalPrefix4;
        example = "10.0";
      };
      prefixLength4 = lib.mkOption {
        description = "ipv4 private prefix length";
        type = lib.types.int;
        default = 24;
      };
      loPrefix = lib.mkOption {
        description = "ULA reserved for host-local service addresses on lo";
        type = types.subnetPrefix6;
        default = "${org.prefix}:ffff";
      };
      loCidr = lib.mkOption {
        description = "CIDR route of loPrefix";
        type = types.subnetCidr6;
        default = "${org.loPrefix}::/${toString org.prefixLength}";
      };
      build-hosts = lib.mkOption {
        description = "list of designated build hosts";
        default = [ ];
        type = lib.types.listOf types.host;
      };
      namespaces = lib.mkOption {
        description = "namespaces for hosts in the organisation";
        default = [ org.endpoint ];
        type = with lib.types; listOf str;
      };
      vpn = lib.mkOption {
        description = "attrset of vpn configurations";
        default = { };
        type = lib.types.attrsOf (lib.types.submodule vpnModule);
      };
      mailserver = lib.mkOption {
        description = "main mailserver";
        default = null;
        type = lib.types.nullOr (lib.types.submodule mailserverModule);
      };
      flake = lib.mkOption {
        description = "flake for this organisation";
        default = { };
        type = with lib.types; attrsOf str;
      };
      role = lib.mkOption {
        description = "role declaration";
        default = { };
        type = lib.types.attrsOf (lib.types.submodule roleModule);
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
        default = [
          "root-0"
          "root-1"
        ];
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
      store = lib.mkOption {
        description = "record of all stores";
        type = lib.types.attrsOf (lib.types.submodule storeModule);
      };
      theme = lib.mkOption {
        description = "colors, wallpaper and fonts";
        default = null;
        type = lib.types.nullOr (lib.types.submodule themeModule);
      };
    };
  };
  appModule =
    { name, config, ... }@args:
    {
      options = (factories.mkEntity (args // { class = "app"; })) // {
        endpoint = lib.mkOption {
          description = "canonical name on internet";
          type = lib.types.str;
        };
        url = lib.mkOption {
          description = "public url including scheme";
          default = "${config.scheme}://${config.endpoint}";
          type = lib.types.str;
        };
        location = lib.mkOption {
          description = "canonical path";
          default = "/";
          type = lib.types.str;
        };
        configurationFile = lib.mkOption {
          description = "path to specific configuration";
          type = lib.types.coercedTo lib.types.str (s: org.inventoryRoot + "/${s}") lib.types.path;
          default = "apps/${config.name}.nix";
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
        database = lib.mkOption {
          description = "app's database";
          default = config.name;
          type = lib.types.str;
        };
        ssl = lib.mkOption {
          description = "let's encrypt and force https";
          default = true;
          type = lib.types.bool;
        };
        scheme = lib.mkOption {
          description = "http or https";
          default = if config.ssl then "https" else "http";
          type = lib.types.str;
        };
      };
    };
  storeModule =
    { name, config, ... }@args:
    {
      options = factories.mkEntity (args // { class = "store"; });
    };

  serviceModule =
    { name, config, ... }@args:
    {
      options = (factories.mkEntity (args // { class = "service"; })) // {
        endpoint = lib.mkOption {
          description = "maybe canonical name on internet";
          default = null;
          type = with lib.types; nullOr str;
        };
        data = lib.mkOption {
          description = "arbitrary data to service";
          type = with lib.types; attrsOf anything;
        };
      };
    };
  userModule =
    { name, config, ... }@args:
    {
      options = (factories.mkEntity (args // { class = "user"; })) // {
        mail = lib.mkEnableOption "internal mail";
        email = lib.mkOption {
          description = "user's email address";
          default = null;
          type = with lib.types; nullOr str;
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
        ids = lib.mkOption {
          description = "entity id in various formats";
          type = lib.types.submodule (factories.idsModule config.id);
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
          type = types.subnetCidr4;
          default = "${vpn.prefix4}.0/${toString vpn.prefixLength4}";
        };
        prefix4 = lib.mkOption {
          description = "ipv4 prefix for peers in vpn";
          type = types.subnetPrefix4;
          default = "${org.prefix4}.${toString vpn.id}";
        };
        prefixLength4 = lib.mkOption {
          description = "ipv4 prefix length for peers in vpn";
          type = lib.types.int;
          default = org.prefixLength4;
        };
        address = lib.mkOption {
          description = "ipv6 vpn address";
          type = types.subnetCidr6;
          default = "${vpn.prefix}::/${toString vpn.prefixLength}";
        };
        addressWithBrackets = lib.mkOption {
          description = "ipv6 vpn address enclosed in square brackets";
          type = types.subnetCidrBracketed6;
          readOnly = true;
          default = "[${vpn.prefix}::]/${toString vpn.prefixLength}";
        };
        prefix = lib.mkOption {
          description = "ipv6 prefix for peers in vpn";
          type = types.subnetPrefix6;
          default = "${org.prefix}:${vpn.ids.hex4}";
        };
        prefixLength = lib.mkOption {
          description = "ipv6 prefix length for peers in vpn";
          type = lib.types.int;
          default = org.prefixLength;
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
          type = lib.types.int;
        };
        gateway = lib.mkOption {
          description = "designated gateway host";
          type = types.host;
        };
        proxy = lib.mkEnableOption "ipv6 proxy through gateway";
        dns = lib.mkOption {
          description = "list of name servers";
          type = with lib.types; listOf types.host;
        };
        resetOnRebuild = lib.mkOption {
          description = "destroy and recreate network device post rebuild";
          type = lib.types.bool;
          default = true;
        };
        allowedTCPPorts = lib.mkOption {
          description = "force all peers to allow these tcp ports in the vpn";
          default = [ ];
          type = with lib.types; listOf int;
        };
        allowedUDPPorts = lib.mkOption {
          description = "force all peers to allow these udp ports in the vpn";
          default = [ ];
          type = with lib.types; listOf int;
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

  roleModule =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          description = "domain name";
          type = lib.types.str;
          default = name;
        };
        services = lib.mkOption {
          description = "services bundled in this role";
          type = lib.types.listOf types.service;
          default = [ ];
        };
        stores = lib.mkOption {
          description = "stores bundled in this role";
          type = lib.types.listOf types.store;
          default = [ ];
        };
      };
    };

  hostModule =
    {
      name,
      config,
      ...
    }@args:
    let
      host = config;
    in
    {
      options = (factories.mkEntity (args // { class = "host"; })) // {
        configurationFile = lib.mkOption {
          description = "path to specific configuration";
          type = lib.types.path;
          default = org.inventoryRoot + "/hosts/${host.name}/configuration.nix";
        };
        boot = lib.mkOption {
          description = "boot method";
          type = lib.types.enum [
            "grub"
            "systemd"
          ];
          default = "systemd";
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
          default = org.inventoryRoot + "/hosts/${host.name}/facter.json";
          type = lib.types.path;
        };
        luksKeyFile = lib.mkOption {
          type = lib.types.str;
          default = "/luks-key";
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
          description = "maybe canonical name on internet";
          default = null;
          type = with lib.types; nullOr str;
        };
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
          type = lib.types.attrsOf (
            lib.types.submodule ({ name, ... }@args: homeModule (args // { inherit host; }))
          );
        };
        network = lib.mkOption {
          description = "networks to configure on host";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule networkModule);
        };
        disk-layouts = lib.mkOption {
          description = "record of disk layouts that applies to host";
          default = { };
          type = lib.types.attrsOf (lib.types.submodule diskModule);
        };
        desktop = lib.mkOption {
          description = "attrset of desktop settings";
          default = { };
          type = lib.types.attrsOf lib.types.anything;
        };
        user = lib.mkOption {
          description = "ledger of users on host";
          readOnly = true;
          default = lib.listToAttrs (
            map (user: lib.nameValuePair org.user.${user}.name org.user.${user}) host.users
          );
          type = lib.types.attrsOf (lib.types.submodule userModule);
        };
        app = lib.mkOption {
          description = "apps configured on the host";
          readOnly = true;
          type = lib.types.attrsOf (lib.types.submodule appModule);
          default = lib.mapAttrs' (_: app: lib.nameValuePair app.name app) (
            lib.filterAttrs (_: app: (lib.elem host.name app.run-on-hosts)) org.app
          );
        };
        service = lib.mkOption {
          description = "services configured on the host";
          readOnly = true;
          type = lib.types.attrsOf (lib.types.submodule serviceModule);
          default = lib.listToAttrs (
            map (service: lib.nameValuePair org.service.${service}.name org.service.${service}) (
              builtins.concatMap (role: org.role.${role}.services) host.roles
            )
          );
        };
        store = lib.mkOption {
          description = "stores configured on the host";
          readOnly = true;
          type = lib.types.attrsOf (lib.types.submodule storeModule);
          default = lib.listToAttrs (
            map (store: lib.nameValuePair org.store.${store}.name org.store.${store}) (
              builtins.concatMap (role: org.role.${role}.stores) host.roles
            )
          );
        };
        entities = lib.mkOption {
          description = "ledger of all entities configured on the host";
          readOnly = true;
          default = lib.listToAttrs (
            builtins.concatMap
              (
                class:
                (map (entity: lib.nameValuePair "${class}-${entity.name}" entity) (lib.attrValues host.${class}))
              )
              [
                "user"
                "app"
                "service"
                "store"
              ]
          );
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
        rescueMode = lib.mkEnableOption "insecure rescue mode.";
      };
      config = {
        network = lib.mapAttrs (
          vpnName: vpn:
          lib.mkDefault {
            inherit (vpn) interface;
            mode = null;
            dns = lib.concatMap (dnsHost: [
              org.host.${dnsHost}.network.${vpnName}.address
              org.host.${dnsHost}.network.${vpnName}.address4
            ]) vpn.dns;
            address = "${vpn.prefix}::${host.ids.hex4}";
            destination = vpn.address;
            address4 = "${vpn.prefix4}.${host.ids.str}";
            destination4 = vpn.address4;
            inherit (vpn) prefixLength prefixLength4;
          }
        ) org.vpn;
      };
    };

  homeModule =
    {
      name,
      host,
      config,
      ...
    }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "${config.username}@${host.name}";
        };
        username = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        configurationFile = lib.mkOption {
          description = "path to specific configuration";
          type = lib.types.path;
          default = org.inventoryRoot + "/homes/${config.name}.nix";
        };
        roles = lib.mkOption {
          type = with lib.types; listOf str;
        };
        hostname = lib.mkOption {
          type = lib.types.str;
          default = host.name;
        };
        stateVersion = lib.mkOption {
          description = "nixos state version";
          type = with lib.types; nullOr str;
          default = host.stateVersion;
        };
      };
    };

  networkModule =
    { name, config, ... }:
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
          type =
            with lib.types;
            nullOr (enum [
              "dhcp"
              "static"
            ]);
          default = null;
        };
        mac = lib.mkOption {
          description = "mac address";
          type = lib.types.nullOr types.mac;
          default = null;
        };
        address = lib.mkOption {
          description = "ipv6 host address (not CIDR)";
          type = with lib.types; nullOr str;
          default = null;
        };
        destination = lib.mkOption {
          description = "ipv6 destination";
          type = with lib.types; nullOr str;
          default = null;
        };
        prefixLength = lib.mkOption {
          description = "ipv6 prefix length";
          type = with lib.types; nullOr int;
          default = null;
        };
        gateway = lib.mkOption {
          description = "ipv6 gateway address";
          type = with lib.types; nullOr str;
          default = null;
        };
        metric = lib.mkOption {
          description = "ipv6 metric for routing: lower takes priority";
          type = with lib.types; nullOr int;
          default = 1024;
        };
        address4 = lib.mkOption {
          description = "ipv4 host address";
          type = with lib.types; nullOr str;
          default = null;
        };
        destination4 = lib.mkOption {
          description = "ipv4 destination";
          type = with lib.types; nullOr str;
          default = null;
        };
        gateway4 = lib.mkOption {
          description = "ipv4 gateway address";
          type = with lib.types; nullOr str;
          default = null;
        };
        prefixLength4 = lib.mkOption {
          description = "ipv4 prefix length";
          type = with lib.types; nullOr int;
          default = null;
        };
        metric4 = lib.mkOption {
          description = "ipv4 metric for routing: lower takes priority";
          type = with lib.types; nullOr int;
          default = config.metric;
        };
        dns = lib.mkOption {
          type = with lib.types; nullOr (listOf str);
          default = null;
        };
        gatewayOnLink = lib.mkEnableOption "onlink for gateway" // {
          type = with lib.types; nullOr bool;
          default = null;
        };
        privacy = lib.mkEnableOption "ipv6 kernel address rotation" // {
          type = with lib.types; nullOr bool;
          default = null;
        };
      };
    };
  diskModule =
    { name, ... }:
    {
      options = {
        name = lib.mkOption {
          type = lib.types.str;
          default = name;
        };
        layout = lib.mkOption {
          type = lib.types.str;
        };
        devices = lib.mkOption {
          description = "unix path to device(s)";
          type = with lib.types; either str (listOf str);
        };
        mountpoint = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
        };
      };
    };

  themeModule =
    { config, ... }:
    {
      options = {
        wallpaper = lib.mkOption {
          description = "path to wallpaper";
          type = lib.types.str;
        };
        vim-colorscheme = lib.mkOption {
          description = "name of vim colorscheme to use (check nixvim for supported schemes)";
          type = with lib.types; nullOr str;
          default = null;
        };
        colors = lib.mkOption {
          description = "flat color mapping with semantic colors attached";
          type = with lib.types; attrsOf str;
          default =
            let
              paletteFile = org.inventoryRoot + "/palette.json";
              palette =
                if builtins.pathExists paletteFile then builtins.fromJSON (builtins.readFile paletteFile) else null;
              colorNames = builtins.attrNames palette;

              colorNameValuePairs = builtins.concatMap (
                colorName:
                let
                  shades = palette.${colorName};
                in
                map (shade: {
                  name = "${colorName}-${shade}";
                  value = shades.${shade};
                }) (builtins.attrNames shades)
              ) colorNames;
              colors = builtins.listToAttrs colorNameValuePairs;
            in
            lib.optionalAttrs (palette != null) (
              with colors;
              colors
              // rec {
                none = "NONE";
                background = neutral-950;
                foreground = neutral-50;

                regular-black = slate-900;
                regular-red = red-400;
                regular-green = green-400;
                regular-yellow = yellow-400;
                regular-blue = blue-400;
                regular-magenta = violet-400;
                regular-cyan = cyan-400;
                regular-white = slate-400;

                bright-black = slate-600;
                bright-red = red-200;
                bright-green = green-200;
                bright-yellow = yellow-200;
                bright-blue = blue-200;
                bright-magenta = violet-200;
                bright-cyan = cyan-200;
                bright-white = slate-50;

                bg-light = neutral-800;
                bg-base = neutral-900;
                bg-shade = background;

                fg-bright = foreground;
                fg-base = neutral-100;
                fg-dimmed = neutral-400;

                fg-inv = bg-base;
                bg-inv = fg-base;

                bg-selected = bg-inv;
                bg-success = regular-green;
                bg-disabled = bright-black;
                bg-error = regular-red;
                bg-warning = regular-yellow;
                bg-info = regular-blue;
                bg-hint = regular-black;

                fg-selected = fg-inv;
                fg-success = regular-black;
                fg-disabled = regular-black;
                fg-error = regular-black;
                fg-warning = regular-black;
                fg-info = regular-black;
                fg-hint = bright-white;

                fg-match = regular-magenta;
                fg-match-selected = regular-magenta;
              }
            );
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
in
{
  options = {
    path = lib.mkOption {
      description = "path";
      type = lib.types.path;
    };
    flakePath = lib.mkOption {
      description = "for builtins.getFlake";
      type = lib.types.str;
      default = toString config.path;
    };
    flake = lib.mkOption {
      description = "flake";
      type = lib.types.attrsOf lib.types.anything;
      default = builtins.getFlake config.flakePath;
    };
    inputs = lib.mkOption {
      description = "inputs";
      type = lib.types.attrsOf lib.types.anything;
      default = config.flake.inputs // {
        self = config.flake;
      };
    };
    org = lib.mkOption {
      description = "org";
      type = lib.types.submodule orgModule;
      default = lib.importTOML (config.path + "/org.toml");
    };
  };
}
