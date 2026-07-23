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
    hashedPasswordFile = org.service.rescue.publicKeys.passwd;
    openssh.authorizedKeys.keyFiles = [
      org.service.rescue.publicKeys.ssh-key
    ];
  };
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = lib.mkForce "yes";
    };
  };
}
