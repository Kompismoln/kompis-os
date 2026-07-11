{ host, org, ... }:
{
  networking.hostId = host.hostId;
  networking.localCommands = ''
    ip -6 route add local ${org.loCidr} dev lo
  '';
  boot.kernel.sysctl = {
    "net.ipv6.ip_nonlocal_bind" = 1;
  };
}
