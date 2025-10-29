# kompis-os/nixos/tls-certs.nix
{
  config,
  lib,
  lib',
  ...
}:

let
  tls-certs = config.kompis-os.tls-certs;
in
{
  options.kompis-os.tls-certs = lib.mkOption {
    type = with lib.types; listOf str;
    default = [ ];
    description = "List of self signed certificates to accept and expose";
  };

  config = lib.mkIf (tls-certs != [ ]) {
    security.pki.certificates = map (
      name: builtins.readFile (lib'.public-artifacts "service" "domain-${name}" "tls-cert")
    ) tls-certs;

    users.groups.tls-cert = {
      members = [
        "nginx"
        #"zitadel"
      ];
    };

    sops.secrets = builtins.listToAttrs (
      map (name: {
        name = "domain-${name}/tls-cert";
        value = {
          sopsFile = lib'.secrets "service" "domain-${name}";
          owner = "root";
          group = "tls-cert";
          mode = "0440";
        };
      }) tls-certs
    );
  };
}
