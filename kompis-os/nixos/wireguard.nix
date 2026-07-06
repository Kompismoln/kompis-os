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

  subnets = builtins.filter (subnet: subnet.enable) (
    map (subnetName: org.subnet.${subnetName}) host.subnets
  );

  peers =
    subnet:
    lib.filter (
      peer:
      lib.elem "peer" peer.roles
      && lib.elem subnet.interface peer.subnets
      && (peer.name == subnet.gateway || host.name == subnet.gateway)
    ) (lib.attrValues org.host);

  isGateway = lib.any (subnet: host.name == subnet.gateway) subnets;
  dnsFor = lib.filter (subnet: lib.elem host.name subnet.dns) subnets;
  proxyFor = lib.filter (subnet: host.name == subnet.gateway && subnet.proxy) subnets;
in
{
  options.kompis-os.wireguard = {
    enable = lib.mkOption {
      description = "enable wireguard subnets on this host";
      type = lib.types.bool;
    };
  };

  config = lib.mkIf cfg.enable {
    services.kresd = lib.mkIf (dnsFor != [ ]) {
      enable = true;

      listenPlain = builtins.concatMap (subnet: [
        "[${subnet.prefix}::${lib'.hex host.id}]:53"
        "${subnet.prefix4}.${toString host.id}:53"
      ]) dnsFor;

      extraConfig = ''
        modules = { 'hints > iterate' }
        ${lib.concatStringsSep "\n" (
          builtins.concatMap (
            subnet:
            map (peer: ''
              hints['${peer.name}.${subnet.namespace}'] = '${subnet.prefix}::${lib'.hex peer.id}'
              hints['${peer.name}.${subnet.namespace}'] = '${subnet.prefix4}.${toString peer.id}'
            '') (peers subnet)
          ) dnsFor
        )}
      '';
    };

    systemd.services."systemd-networkd".preStop = lib.concatStringsSep "\n" (
      map (subnet: "${pkgs.iproute2}/bin/ip link delete ${subnet.interface}") (
        lib.filter (subnet: subnet.resetOnRebuild) subnets
      )
    );

    networking = {
      wireguard.enable = true;
      networkmanager.unmanaged = map (interface: "interface-name:${interface}") host.subnets;

      nat = lib.mkIf (proxyFor != [ ]) {
        enable = true;
        enableIPv6 = true;
        internalInterfaces = map (subnet: subnet.interface) proxyFor;
        inherit (host) externalInterface;
      };

      firewall = {
        allowedUDPPorts = map (subnet: subnet.port) (
          lib.filter (subnet: host.name == subnet.gateway) subnets
        );
        trustedInterfaces = map (subnet: subnet.interface) (
          builtins.filter (subnet: subnet.trusted) subnets
        );
        interfaces = lib.mkMerge [
          (lib.listToAttrs (
            map (
              subnet:
              lib.nameValuePair subnet.interface {
                inherit (subnet) allowedTCPPorts allowedUDPPorts;
              }
            ) (builtins.filter (subnet: !subnet.trusted) subnets)
          ))
          (lib.listToAttrs (
            map (
              subnet:
              lib.nameValuePair subnet.interface {
                allowedTCPPorts = [ 53 ];
                allowedUDPPorts = [ 53 ];
              }
            ) (builtins.filter (subnet: !subnet.trusted) dnsFor)
          ))
        ];
      };
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
            wireguardPeers = map (
              peer:
              let
                base = {
                  PublicKey = builtins.readFile (lib'.public-artifacts "host" peer.name "${subnet.interface}-key");
                  AllowedIPs =
                    if peer.name == subnet.gateway then
                      [
                        subnet.address
                        subnet.address4
                        "::/0"
                      ]
                    else
                      [
                        "${subnet.prefix}::${lib'.hex peer.id}/128"
                        "${subnet.prefix4}.${toString peer.id}/32"
                      ];
                };
                serverConfig = {
                  Endpoint = "${peer.endpoint}:${toString subnet.port}";
                };
                clientConfig = {
                  PersistentKeepalive = subnet.keepalive;
                };
              in
              base // (if peer.name == subnet.gateway then serverConfig else clientConfig)
            ) (lib.filter (peer: peer.name != host.name) (peers subnet));
          }
        ) subnets
      );

      networks = lib.listToAttrs (
        map (
          subnet:
          lib.nameValuePair "10-${subnet.interface}" {
            matchConfig.Name = subnet.interface;
            address = [
              "${subnet.prefix}::${lib'.hex host.id}/${toString subnet.prefix-length}"
              "${subnet.prefix4}.${toString host.id}/${toString subnet.prefix4-length}"
            ];
            dns = builtins.concatMap (dns: [
              "${subnet.prefix}::${lib'.hex org.host.${dns}.id}"
              "${subnet.prefix4}.${toString org.host.${dns}.id}"
            ]) subnet.dns;
            routes =
              (lib.optionals (host.name == subnet.gateway) [
                {
                  Destination = subnet.address;
                }
                {
                  Destination = subnet.address4;
                  Scope = "link";
                }
              ])
              ++ (lib.optionals (subnet.proxy && host.name != subnet.gateway) [
                {
                  Gateway = "${subnet.prefix}::${lib'.hex org.host.${subnet.gateway}.id}";
                  Destination = "::/0";
                }
              ]);
            networkConfig = {
              DHCP = "no";
            };
          }
        ) subnets
      );
    };
  };
}
