{
  host,
  lib,
  org,
  ...
}:
{
  time.timeZone = org.timezone;
  i18n.defaultLocale = org.locale;
  system.stateVersion = host.stateVersion;
  networking.hostName = host.name;
  hardware.facter.reportPath = if host.hardwareReport == "facter" then host.facterFile else null;

  # Leaving out hardware conf entirely is likely a mistake that'll switch the system into an unreachable state.
  # The error NixOS raises if hostPlatform isn't set is a currently a useful signal that no hardware conf is loaded.
  #nixpkgs.hostPlatform = host.system;
}
// lib.optionalAttrs host.rescueMode {
  users.mutableUsers = false;
  users.users.root = {
    hashedPassword = "$6$TeS3rgBzEDTxk7eb$PN0BjGcoZa1cb29HQJrOHGqVzIhUIs115eP01k.CkenNpi0fTnfxwHK9bFSXUC2zavxi5sEt.pwqcTy1rpCas1";
    openssh.authorizedKeys.keyFiles = [
      org.service.rescue.public-artifacts.ssh-key
    ];
  };
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "yes";
    };
  };
}
