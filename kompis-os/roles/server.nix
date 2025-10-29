# kompis-os/roles/server.nix
{ inputs, ... }:
{
  flake.nixosModules.server =
    {
      host,
      lib,
      org,
      ...
    }:
    {
      imports = [
        ../nixos/dns-hints.nix
        ../nixos/egress-proxy.nix
        ../nixos/fail2ban.nix
        ../nixos/monitor.nix
        ../nixos/reverse-tunnel.nix
        ../nixos/sendmail.nix
        ../nixos/tls-certs.nix
      ];

      nixpkgs.overlays = [
        (import ../overlays/pgsql-tools.nix { inherit inputs; })
      ];

      kompis-os = {
        dns-hints = lib.mkIf (lib.hasAttr "dnsFor" org.host.${host.name}) {
          enable = true;
          subnet = org.host.${host.name}.dnsFor;
        };

        egress-proxy.enable = true;
        fail2ban.enable = true;
        reverse-tunnel.enable = true;
        sendmail = true;
        tls-certs = org.namespaces;
      };

    };
}
