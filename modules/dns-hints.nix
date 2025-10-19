{
  lib,
  host,
  config,
  org,
  ...
}:
let
  cfg = config.kompis-os.dns-hints;
  subnet = org.subnet.${cfg.subnet};
  listen = peerAddress subnet host;
  hints = lib.mapAttrsToList hint org.host;

  peerAddress =
    subnet: peer: builtins.replaceStrings [ "x" ] [ (toString peer.id) ] subnet.peerAddress;

  hint =
    hostname: hostconf: "hints['${hostname}.${subnet.namespace}'] = '${peerAddress subnet hostconf}'";
in
{
  options.kompis-os.dns-hints = {
    enable = lib.mkEnableOption "dns hints on this host";
    subnet = lib.mkOption {
      type = lib.types.str;
      description = "Which subnet to provide dns hints for";
    };
  };
  config = lib.mkIf (cfg.enable) {
    services.kresd = {
      enable = true;
      listenPlain = [ "${listen}:53" ];
      extraConfig = ''
        modules = { 'hints > iterate' }
        ${lib.concatStringsSep "\n" hints}
      '';
    };
  };
}
