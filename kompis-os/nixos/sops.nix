# kompis-os/nixos/sops.nix
{
  config,
  inputs,
  lib,
  host,
  ...
}:
let
  cfg = config.kompis-os.sops;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.kompis-os.sops = {
    enable = lib.mkOption {
      description = "enable sops-nix";
      type = lib.types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {

    sops = {
      defaultSopsFile = host.secrets.sopsFile;
      age = {
        keyFile = host.secrets.decryptionKey;
        sshKeyPaths = [ ];
      };
    };
  };
}
