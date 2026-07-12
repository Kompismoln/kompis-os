# nixos/org/ssh.nix
{
  services = {
    fail2ban.jails = {
      sshd.settings = {
        filter = "sshd[mode=normal]";
      };
    };

    openssh = {
      enable = true;
      extraConfig = ''
        Match User *
          PasswordAuthentication no
          ChallengeResponseAuthentication no
          KbdInteractiveAuthentication no
      '';

      hostKeys = [
        {
          path = "/keys/ssh_host_ed25519_key";
          type = "ed25519";
        }
      ];
    };
  };
}
