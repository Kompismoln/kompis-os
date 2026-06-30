# kompis-os/nixos/wireguard.nix
{
  config,
  host,
  lib,
  lib',
  pkgs,
  org,
  ...
}:

let
  cfg = config.kompis-os.wireguard;

  eachSubnet = map (subnet: org.subnet.${subnet}) host.subnets;

  peerAddress =
    subnet: peerCfg: builtins.replaceStrings [ "x" ] [ (toString peerCfg.id) ] subnet.peerAddress;

  createPeer =
    subnet: peer: peerCfg:
    let
      base = {
        PublicKey = builtins.readFile (lib'.public-artifacts "host" peer "${subnet.interface}-key");
        AllowedIPs = [
          (if peer == subnet.gateway then subnet.address else "${peerAddress subnet peerCfg}/32")
        ];
      };
      serverConfig = {
        Endpoint = "${peerCfg.endpoint}:${toString subnet.port}";
      };
      clientConfig = {
        PersistentKeepalive = subnet.keepalive;
      };
    in
    base // (if peer == subnet.gateway then serverConfig else clientConfig);

  peers =
    subnet:
    lib.filterAttrs (
      otherHostName: otherHostCfg:
      otherHostName != host.name
      && lib.elem "peer" otherHostCfg.roles
      && lib.elem subnet.interface otherHostCfg.subnets
      && (otherHostName == subnet.gateway || host.name == subnet.gateway)
    ) org.host;

  isGateway = lib.any (subnet: host.name == subnet.gateway) eachSubnet;
in
{
  options.kompis-os.wireguard.enable = lib.mkOption {
    description = "enable wireguard subnets on this host";
    type = lib.types.bool;
    default = lib.elem "peer" host.roles;
  };

  config = lib.mkIf cfg.enable {

    systemd.services."systemd-networkd".preStop = lib.concatStringsSep "\n" (
      map (subnet: "${pkgs.iproute2}/bin/ip link delete ${subnet.interface}") (
        lib.filter (subnet: subnet.resetOnRebuild) eachSubnet
      )
    );

    networking = {
      wireguard.enable = true;
      networkmanager.unmanaged = map (interface: "interface-name:${interface}") host.subnets;

      firewall.interfaces = lib.listToAttrs (
        map (
          subnet:
          lib.nameValuePair subnet.interface {
            inherit (subnet) allowedTCPPortRanges;
          }
        ) eachSubnet
      );

      firewall.allowedUDPPorts = map (subnet: subnet.port) (
        lib.filter (subnet: host.name == subnet.gateway) eachSubnet
      );
    };

    sops.secrets = lib.listToAttrs (
      map (
        interface:
        lib.nameValuePair "${interface}-key" {
          owner = "systemd-network";
          group = "systemd-network";
        }
      ) host.subnets
    );

    boot.kernel.sysctl = lib.mkIf isGateway {
      "net.ipv4.ip_forward" = 1;
      "net.ipv6.conf.all.forwarding" = 1;
    };

    systemd.network = {
      enable = true;

      netdevs = lib.listToAttrs (
        map (
          subnet:
          lib.nameValuePair "10-${subnet.interface}" {
            netdevConfig = {
              Kind = "wireguard";
              Name = subnet.interface;
            };
            wireguardConfig = {
              PrivateKeyFile = config.sops.secrets."${subnet.interface}-key".path;
              ListenPort = lib.mkIf (host.name == subnet.gateway) subnet.port;
            };
            wireguardPeers = lib.mapAttrsToList (createPeer subnet) (peers subnet);
          }
        ) eachSubnet
      );

      networks = lib.listToAttrs (
        map (
          subnet:
          lib.nameValuePair "10-${subnet.interface}" {
            matchConfig.Name = subnet.interface;
            address = [ "${peerAddress subnet host}/24" ];
            dns = map (dns: peerAddress subnet org.host.${dns}) subnet.dns;
            routes = lib.optional (host.name == subnet.gateway) {
              Destination = subnet.address;
              Scope = "link";
            };
            networkConfig = {
              DHCP = "no";
              IPv6PrivacyExtensions = "kernel";
            };
          }
        ) eachSubnet
      );
    };
  };
}
