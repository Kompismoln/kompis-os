{
  lib,
  pkgs,
  config,
  ...
}:
let

  cfg = config.system.autoRollback;

  currentSystem = "/run/current-system/sw/bin";
  profiles = "/nix/var/nix/profiles";

  nixos-confirm = pkgs.writers.writeDashBin "nixos-confirm" ''
    set -e

    if test -n "$1"; then
      gen=${profiles}/system-$1-link
    else
      gen=/run/current-system
    fi
    /run/current-system/sw/bin/systemctl stop \
      auto-rollback.service auto-rollback.timer
    echo "Confirming generation $gen as good"
    ln -snfv "$(readlink "$gen")" "${profiles}/system-good"
  '';

in
{
  options.system.autoRollback = {
    enable = lib.mkEnableOption "automatic rollback to the previous generation";

    timeout = lib.mkOption {
      type = lib.types.str;
      default = "5 min";
      example = "30 s";
      description = ''
        Timeout for the automatic rollback.
        See {manpage}`systemd.time(7)` for the format.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ nixos-confirm ];

    systemd.services.auto-rollback = {
      unitConfig.X-RestartIfChanged = false;
      script = ''
        current=/run/current-system
        good=${profiles}/system-good

        if ! test -L "$good"; then
          echo "No generation is marked as good, not rolling back"
          exit 0
        fi;

        if test $(readlink "$current") != "$(readlink "$good")"; then
          ${pkgs.util-linux}/bin/wall "Rolling back to $(readlink "$good") in 30s"
          sleep 30
          "$good/bin/switch-to-configuration" test
        fi
      '';
    };

    systemd.timers.auto-rollback = {
      wantedBy = [ "timers.target" ];
      timerConfig.RemainAfterElapse = false;
      timerConfig.OnActiveSec = cfg.timeout;
    };
  };

}
