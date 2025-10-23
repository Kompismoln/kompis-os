# roles/peer.nix
{
  flake.nixosModules.peer = {
    imports = [
      ../nixos/locksmith.nix
      ../nixos/nix.nix
      ../nixos/preserve.nix
      ../nixos/sops.nix
      ../nixos/ssh.nix
      ../nixos/tls-certs.nix
      ../nixos/users.nix
      ../nixos/wireguard.nix
    ];

    kompis-os = {
      users.admin = {
        class = "user";
        groups = [ "wheel" ];
      };
      tls-certs = [ "km" ];
      locksmith.enable = true;
      sops.enable = true;
      ssh.enable = true;
    };
  };
}
