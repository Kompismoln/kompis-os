{
  config,
  host,
  lib,
  lib',
  org,
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
      time.timeZone = org.timezone;
      i18n.defaultLocale = org.locale;
      system.stateVersion = host.stateVersion;
      networking.hostName = host.name;
      #nixpkgs.hostPlatform = host.system;
      hardware.facter.reportPath = if host.hardwareReport == "facter" then host.facterFile else null;
    }

    (lib.mkIf cfg.rescueMode {
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
