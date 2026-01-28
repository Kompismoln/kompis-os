# kompis-os/roles/server.nix
{ inputs, self, ... }:
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
        ../nixos/shell.nix
        ../nixos/tls-certs.nix
      ];

      nixpkgs.overlays = [
        (import ../overlays/pgsql-tools.nix { inherit inputs; })
      ];

      kompis-os = {
        dns-hints = lib.mkIf (org.host.${host.name}.dnsFor != null) {
          enable = true;
          subnet = org.host.${host.name}.dnsFor;
        };

        # msmtp conflicts with postfix
        sendmail.enable = host.name != self.org.mailserver.host;

        shell.enable = true;
        egress-proxy.enable = true;
        fail2ban.enable = true;
        reverse-tunnel.enable = true;
        tls-certs = org.namespaces;
      };

    };
}
