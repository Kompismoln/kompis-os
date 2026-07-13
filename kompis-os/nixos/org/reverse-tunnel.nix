# nixos/org/reverse-tunnel.nix
{
  lib,
  org,
  ...
}:
{
  imports = [
    ../principals.nix
  ];

  kompis-os.principals.reverse-tunnel = {
    class = "service";
    passwd = true;
  };

  networking.firewall.allowedTCPPorts = [
    org.service.reverse-tunnel.port
  ];

  services.openssh = {
    enable = true;
    settings = {
      GatewayPorts = lib.mkForce "clientspecified";
    };

    extraConfig = ''
      Match User reverse-tunnel
        ForceCommand /bin/false
        AllowTcpForwarding remote
        X11Forwarding no
        AllowAgentForwarding no
        PermitTunnel no
    '';
  };
}
