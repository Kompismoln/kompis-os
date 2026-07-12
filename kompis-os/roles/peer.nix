# kompis-os/roles/peer.nix
{ inputs, ... }:
{
  flake.nixosModules.peer = {
    imports = [
      ../nixos/org/locksmith.nix
      ../nixos/org/ssh.nix
      ../nixos/org/networking.nix
      ../nixos/org/nix.nix
      ../nixos/preserve.nix
      ../nixos/sops.nix
      ../nixos/state.nix
      ../nixos/tls-certs.nix
      ../nixos/users.nix
      ../nixos/wireguard.nix
    ];

    kompis-os = {
      users.admin = {
        class = "user";
        groups = [ "wheel" ];
        stateful = false;
      };
      tls-certs = inputs.org.namespaces;
      wireguard.enable = true;
      sops.enable = true;
      #state.enable = true;
    };
  };
}
