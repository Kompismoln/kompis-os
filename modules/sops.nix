{
  config,
  inputs,
  lib,
  host,
  ...
}:
let
  inherit (lib)
    mkOption
    mkIf
    ;
  cfg = config.kompis-os.sops;
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
  ];

  options.kompis-os.sops = {
    enable = mkOption {
      description = "enable sops-nix";
      type = lib.types.bool;
      default = true;
    };
  };

  config = mkIf (cfg.enable) {

    sops = {
      defaultSopsFile = ../enc/host-${host.name}.yaml;
      age = {
        keyFile = "/keys/host-${host.name}";
        sshKeyPaths = [ ];
      };
    };

  };
}
