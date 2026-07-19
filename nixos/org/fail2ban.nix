{
  lib,
  org,
  ...
}:
{
  services.fail2ban = {
    enable = true;
    maxretry = 1;
    bantime = "1d";
    bantime-increment.enable = true;
    ignoreIP = map (vpn: vpn.address4) (lib.attrValues org.vpn);
  };
}
