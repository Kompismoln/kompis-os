{
  flake.nixosModules.cinnamon-office =
    {
      org,
      ...
    }:
    {
      services.restic.server = {
        enable = true;
        listenAddress = toString org.ids.restic.port;
        extraFlags = [ "--no-auth" ];
      };
    };
}
