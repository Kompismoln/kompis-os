{
  config,
  inputs,
  lib,
  lib',
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

  config = lib.mkIf (cfg.enable) {

    sops = {
      defaultSopsFile = lib'.secrets "host" host.name;
      age = {
        keyFile = "/keys/host-${host.name}";
        sshKeyPaths = [ ];
      };
    };
  };
}
