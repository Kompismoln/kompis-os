# nixos/org/tls-certs.nix
{
  lib,
  org,
  ...
}:

{
  config = lib.mkIf (org.namespaces != [ ]) {
    security.pki.certificates = map (
      name: builtins.readFile org.service.${"domain-${name}"}.public-artifacts.tls-cert
    ) org.namespaces;

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
          inherit (org.service.${"domain-${name}"}.secrets) sopsFile;
          owner = "root";
          group = "tls-cert";
          mode = "0440";
        };
      }) org.namespaces
    );
  };
}
