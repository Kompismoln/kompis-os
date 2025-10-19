# modules/reverse-tunnel.nix
{
  config,
  lib,
  lib',
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkForce
    ;
  cfg = config.kompis-os.reverse-tunnel;
in
{
  options.kompis-os.reverse-tunnel = {
    enable = mkEnableOption "respond to phone home from stranded clients";
  };

  config = mkIf (cfg.enable) {
    kompis-os.users.reverse-tunnel = {
      class = "service";
      passwd = true;
    };

    networking.firewall.allowedTCPPorts = [
      lib'.ids.reverse-tunnel.port
    ];

    services.openssh = {
      enable = true;
      settings = {
        GatewayPorts = mkForce "clientspecified";
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
