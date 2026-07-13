# roles/server.nix
{
  flake.nixosModules.server = {
    imports = [
      ../nixos/org/egress-proxy.nix
      ../nixos/org/fail2ban.nix
      ../nixos/org/reverse-tunnel.nix
      ../nixos/org/sendmail.nix
      ../nixos/org/shell.nix
      ../nixos/org/tls-certs.nix
    ];
  };
}
