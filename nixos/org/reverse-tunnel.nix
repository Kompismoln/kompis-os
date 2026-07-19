# nixos/org/reverse-tunnel.nix
{
  lib,
  ...
}:
{
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
