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

  eachSubnet = lib.filterAttrs (iface: ifaceCfg: ifaceCfg.enable) org.subnet;

  peerAddress =
    ifaceCfg: peerCfg: builtins.replaceStrings [ "x" ] [ (toString peerCfg.id) ] ifaceCfg.peerAddress;

  createPeer =
    iface: ifaceCfg: peer: peerCfg:
    let
      base = {
        PublicKey = builtins.readFile (lib'.public-artifacts "host" peer "${iface}-key");
        AllowedIPs = [
          (if peer == ifaceCfg.gateway then ifaceCfg.address else "${peerAddress ifaceCfg peerCfg}/32")
        ];
      };
      serverConfig = {
        Endpoint = "${peerCfg.endpoint}:${toString ifaceCfg.port}";
      };
      clientConfig = {
        PersistentKeepalive = ifaceCfg.keepalive;
      };
    in
    base // (if peer == ifaceCfg.gateway then serverConfig else clientConfig);

  peers =
    iface: ifaceCfg:
    lib.filterAttrs (
      otherHostName: otherHostCfg:
      otherHostName != host.name
      && lib.elem "peer" otherHostCfg.roles
      && lib.elem iface otherHostCfg.subnets
      && (otherHostName == ifaceCfg.gateway || host.name == ifaceCfg.gateway)
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
        lib.filterAttrs (_: ifaceCfg: ifaceCfg.resetOnRebuild) eachSubnet
      )
    );

    networking = {
      wireguard.enable = true;
      networkmanager.unmanaged = map (iface: "interface-name:${iface}") (lib.attrNames eachSubnet);

      interfaces = lib.mapAttrs (_: _: {
        useDHCP = false;
      }) eachSubnet;

      firewall.interfaces = lib.mapAttrs (_: ifaceCfg: {
        inherit (ifaceCfg) allowedTCPPortRanges;
      }) eachSubnet;

      firewall.allowedUDPPorts = lib.mapAttrsToList (iface: ifaceCfg: ifaceCfg.port) (
        lib.filterAttrs (iface: ifaceCfg: host.name == ifaceCfg.gateway) eachSubnet
      );
    };

    sops.secrets = lib.mapAttrs' (
      iface: _:
      lib.nameValuePair "${iface}-key" {
        owner = "systemd-network";
        group = "systemd-network";
      }
    ) eachSubnet;

    boot.kernel.sysctl."net.ipv4.ip_forward" = lib.any (ifaceCfg: host.name == ifaceCfg.gateway) (
      lib.attrValues eachSubnet
    );

    systemd.network = {
      enable = true;

      netdevs = lib.mapAttrs' (
        iface: ifaceCfg:
        lib.nameValuePair "10-${iface}" {
          netdevConfig = {
            Kind = "wireguard";
            Name = iface;
          };
          wireguardConfig = {
            PrivateKeyFile = config.sops.secrets."${iface}-key".path;
            ListenPort = lib.mkIf (host.name == ifaceCfg.gateway) ifaceCfg.port;
          };
          wireguardPeers = lib.mapAttrsToList (createPeer iface ifaceCfg) (peers iface ifaceCfg);
        }
      ) eachSubnet;

      networks = lib.mapAttrs' (
        iface: ifaceCfg:
        lib.nameValuePair "10-${iface}" {
          matchConfig.Name = iface;
          address = [ "${peerAddress ifaceCfg host}/24" ];
          dns = map (dns: peerAddress ifaceCfg org.host.${dns}) ifaceCfg.dns;
          routes = lib.optional (host.name == ifaceCfg.gateway) {
            Destination = ifaceCfg.address;
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
