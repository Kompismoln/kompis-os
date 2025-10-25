# modules/egress-proxy.nix
{
  config,
  lib,
  ...
}:
let
  cfg = config.kompis-os.egress-proxy;
in
{
  options.kompis-os.egress-proxy = {
    enable = lib.mkEnableOption "SOCKS proxy service";
  };

  config = lib.mkIf (cfg.enable) {
    kompis-os.users.egress-proxy = {
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
  };
}
