# roles/peer.nix
{
  flake.nixosModules.peer = {
    imports = [
      ../nixos/org/ssh.nix
      ../nixos/org/networking.nix
      ../nixos/org/nix.nix
      ../nixos/org/sops.nix
      ../nixos/org/wireguard.nix
    ];
  };
}
