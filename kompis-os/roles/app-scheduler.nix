# kompis-os/roles/app-scheduler.nix
{
  flake.nixosModules.app-scheduler =
    {
      lib,
      host,
      org,
      ...
    }:
    let
      apps = lib.filter (app: lib.elem host.name app.run-on-hosts) (lib.attrValues org.app);
    in
    {
      imports = map (
        app:
        (
          {
            inputs,
            config,
            host,
            pkgs,
            org,
            ...
          }:
          (import app.configurationFile) {
            inherit
              app
              inputs
              config
              host
              pkgs
              org
              ;
          }
        )
      ) apps;

      config = lib.mkMerge (
        map (app: {
          services.nginx.virtualHosts = lib.genAttrs (app.altpoints or [ ]) (_: {
            forceSSL = true;
            enableACME = true;
            locations."/".return = "301 https://${app.endpoint}$request_uri";
          });
        }) apps
      );
    };
}
