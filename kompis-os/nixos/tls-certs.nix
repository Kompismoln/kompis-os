{
  config,
  lib,
  lib',
  ...
}:

let
  inherit (lib)
    mkOption
    mkIf
    types
    ;

  tls-certs = config.kompis-os.tls-certs;

in
{
  options.kompis-os.tls-certs = mkOption {
    type = types.listOf types.str;
    default = [ ];
    description = "List of self signed certificates to accept and expose";
  };

  config = mkIf (tls-certs != [ ]) {
    security.pki.certificates = builtins.map (
      name: builtins.readFile (lib'.public-artifacts "service" "domain-${name}" "tls-cert")
    ) tls-certs;

    users.groups.tls-cert = {
      members = [
        "nginx"
        #"zitadel"
      ];
    };

    sops.secrets = builtins.listToAttrs (
      builtins.map (name: {
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
