# modules/ssh.nix
{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
  cfg = config.kompis-os.ssh;
in
{
  options.kompis-os.ssh = {
    enable = mkEnableOption "ssh server";
  };

  config = mkIf (cfg.enable) {

    services.fail2ban.jails = {
      sshd.settings = {
        filter = "sshd[mode=normal]";
      };
    };

    services.openssh.extraConfig = ''
      Match User *
        PasswordAuthentication no
        ChallengeResponseAuthentication no
        KbdInteractiveAuthentication no
    '';
    #programs.ssh.knownHosts = mapAttrs (host: cfg: {
    #  hostNames = [
    #    "${host}.kompismoln.se"
    #    "${host}.km"
    #    cfg.address
    #  ];
    #  publicKeyFile = ../public-keys/host-${host}-ssh-key.pub;
    #}) hosts;

    services.openssh.hostKeys = [
      {
        path = "/keys/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];
  };
}
