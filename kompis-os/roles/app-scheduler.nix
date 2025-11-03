# kompis-os/roles/app-scheduler.nix
{ inputs, ... }:
{
  flake.nixosModules.app-scheduler =
    {
      lib,
      lib',
      host,
      org,
      ...
    }:
    let
      apps = lib.filter (app: lib.elem host.name org.app.${app}.run-on-hosts) (
        lib.attrNames inputs.org.app
      );
    in
    {
      imports = [
      ]
      ++ map (app: lib'.app-config app) apps;

      config = lib.mkMerge (
        map (
          app:
          let
            appCfg = org.app.${app};
          in
          {
            services.nginx.virtualHosts = lib.genAttrs (appCfg.altpoints or [ ]) (altpoint: {
              forceSSL = true;
              enableACME = true;
              locations."/".return = "301 https://${appCfg.endpoint}$request_uri";
            });
          }
        ) apps
      );
    };
}
