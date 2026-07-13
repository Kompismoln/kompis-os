# kompis-os/roles/peer.nix
{
  flake.nixosModules.peer = {
    imports = [
      ../nixos/org/locksmith.nix
      ../nixos/org/ssh.nix
      ../nixos/org/networking.nix
      ../nixos/org/nix.nix
      ../nixos/org/sops.nix
      ../nixos/org/tls-certs.nix
      ../nixos/org/wireguard.nix
      ../nixos/org/users.nix
    ]
    ++ [
      ../nixos/principals.nix
      ../nixos/preserve.nix
    ];

  };
}
