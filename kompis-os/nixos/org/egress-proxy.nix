# nixos/org/egress-proxy.nix
{
  imports = [
    ../principals.nix
  ];

  kompis-os.principals.egress-proxy = {
    class = "service";
  };

  services.openssh.extraConfig = ''
    Match User egress-proxy
      AllowTcpForwarding local
      X11Forwarding no
      AllowAgentForwarding no
      PermitTunnel no
      PermitTTY no
  '';
}
