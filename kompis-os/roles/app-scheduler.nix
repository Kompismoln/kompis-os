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
      apps = lib.filter (appname: lib.elem host.name org.app.${appname}.run-on-hosts) (
        lib.attrNames inputs.org.app
      );
    in
    {
      imports = map (appname: lib'.app-config appname) apps;

      config = lib.mkMerge (
        map (
          appname:
          let
            app = org.app.${appname};
          in
          {
            services.nginx.virtualHosts = lib.genAttrs (app.altpoints or [ ]) (altpoint: {
              forceSSL = true;
              enableACME = true;
              locations."/".return = "301 https://${app.endpoint}$request_uri";
            });
          }
        ) apps
      );
    };
}
