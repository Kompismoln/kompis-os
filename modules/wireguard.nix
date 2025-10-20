# modules/wireguard.nix
{
  config,
  host,
  lib,
  pkgs,
  org,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrsToList
    ;

  cfg = config.kompis-os.wireguard;

  eachSubnet = filterAttrs (iface: cfg: cfg.enable) org.subnet;

  peerAddress =
    subnet: peer: builtins.replaceStrings [ "x" ] [ (toString peer.id) ] subnet.peerAddress;

  createPeer =
    iface: subnet: peerName: peerCfg:
    let
      base = {
        PublicKey = builtins.readFile ../public-keys/host-${peerName}-${iface}-key.pub;
        AllowedIPs = [
          (if peerName == subnet.gateway then subnet.address else "${peerAddress subnet peerCfg}/32")
        ];
      };
      serverConfig = {
        Endpoint = "${peerCfg.endpoint}:${toString subnet.port}";
      };
      clientConfig = {
        PersistentKeepalive = subnet.keepalive;
      };
    in
    base // (if peerName == subnet.gateway then serverConfig else clientConfig);

  peers =
    iface: subnet:
    filterAttrs (
      otherHostName: otherHostCfg:
      otherHostName != host.name
      && lib.elem "peer" otherHostCfg.roles
      && lib.elem iface otherHostCfg.subnets
      && (otherHostName == subnet.gateway || host.name == subnet.gateway)
    ) org.host;

in
{
  options.kompis-os.wireguard.enable = lib.mkOption {
    description = "enable wireguard subnets on this host";
    type = lib.types.bool;
    default = lib.elem "peer" host.roles;
  };

  config = lib.mkIf (cfg.enable) {

    systemd.services."systemd-networkd".preStop = lib.concatStringsSep "\n" (
      lib.mapAttrsToList (iface: _: "${pkgs.iproute2}/bin/ip link delete ${iface}") (
        lib.filterAttrs (_: cfg: cfg.resetOnRebuild) eachSubnet
      )
    );

    networking = {
      wireguard.enable = true;
      networkmanager.unmanaged = map (iface: "interface-name:${iface}") (lib.attrNames eachSubnet);
      firewall.interfaces = lib.mapAttrs (_: subnet: {
        inherit (subnet) allowedTCPPortRanges;
      }) eachSubnet;
      firewall.allowedUDPPorts = lib.mapAttrsToList (iface: cfg: cfg.port) (
        lib.filterAttrs (iface: cfg: host.name == cfg.gateway) eachSubnet
      );
      interfaces = lib.mapAttrs (_: _: { useDHCP = false; }) eachSubnet;
    };

    sops.secrets = lib.mapAttrs' (
      iface: cfg:
      lib.nameValuePair "${iface}-key" {
        owner = "systemd-network";
        group = "systemd-network";
      }
    ) eachSubnet;

    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.any (cfg: host.name == cfg.gateway) (
      lib.attrValues eachSubnet
    );

    systemd.network = {
      enable = true;

      netdevs = lib.mapAttrs' (
        iface: cfg:
        lib.nameValuePair "10-${iface}" {
          netdevConfig = {
            Kind = "wireguard";
            Name = iface;
          };
          wireguardConfig = {
            PrivateKeyFile = config.sops.secrets."${iface}-key".path;
            ListenPort = lib.mkIf (host.name == cfg.gateway) cfg.port;
          };
          wireguardPeers = mapAttrsToList (createPeer iface cfg) (peers iface cfg);
        }
      ) eachSubnet;

      networks = lib.mapAttrs' (
        iface: cfg:
        lib.nameValuePair "10-${iface}" {
          matchConfig.Name = iface;
          address = [ "${peerAddress cfg host}/24" ];
          dns = map (dns: peerAddress cfg org.host.${dns}) cfg.dns;
          routes = lib.optional (host.name == cfg.gateway) {
            Destination = cfg.address;
            Scope = "link";
          };
          networkConfig = {
            DHCP = "no";
            IPv6PrivacyExtensions = "kernel";
          };
        }
      ) eachSubnet;
    };
  };
}
