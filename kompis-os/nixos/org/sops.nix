# nixos/org/sops.nix
{
  inputs,
  host,
  ...
}:
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  sops = {
    defaultSopsFile = host.secrets.sopsFile;
    age = {
      keyFile = host.secrets.decryptionKey;
      sshKeyPaths = [ ];
    };
  };
}
