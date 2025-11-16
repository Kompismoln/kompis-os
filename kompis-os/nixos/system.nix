{
  config,
  host,
  lib,
  lib',
  ...
}:
let
  cfg = config.kompis-os.sysadm;
in
{
  options.kompis-os.sysadm = {
    rescueMode = lib.mkEnableOption "insecure rescue mode.";
  };

  config = lib.mkMerge [
    {
      time.timeZone = "Europe/Stockholm";
      i18n.defaultLocale = "en_US.UTF-8";
      system.stateVersion = host.stateVersion;
      networking.hostName = host.name;
      nixpkgs.hostPlatform = host.system;
    }

    (lib.mkIf (cfg.rescueMode) {
      users.mutableUsers = false;
      users.users.root = {
        hashedPassword = "$6$TeS3rgBzEDTxk7eb$PN0BjGcoZa1cb29HQJrOHGqVzIhUIs115eP01k.CkenNpi0fTnfxwHK9bFSXUC2zavxi5sEt.pwqcTy1rpCas1";
        openssh.authorizedKeys.keyFiles = [
          (lib'.public-artifacts "service" "rescue" "ssh-key")
        ];
      };
      services.openssh = {
        enable = true;
        settings = {
          PermitRootLogin = lib.mkForce "yes";
        };
      };
    })
  ];
}
