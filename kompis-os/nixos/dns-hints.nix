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

  peerAddress =
    subnet: peer: builtins.replaceStrings [ "x" ] [ (toString peer.id) ] subnet.peerAddress;

  hint = host: hostCfg: "hints['${host}.${subnet.namespace}'] = '${peerAddress subnet hostCfg}'";
  peers = lib.filterAttrs (host: hostCfg: lib.elem "peer" hostCfg.roles) org.host;
  hints = lib.mapAttrsToList hint peers;
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
