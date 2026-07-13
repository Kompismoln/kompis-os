# modules/reverse-tunnel.nix
{
  config,
  lib,
  org,
  ...
}:
let
  cfg = config.kompis-os.reverse-tunnel;
in
{
  options.kompis-os.reverse-tunnel = {
    enable = lib.mkEnableOption "respond to phone home from stranded clients";
  };

  config = lib.mkIf cfg.enable {
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
  };
}
