# lib/ids.nix
{
  loki = {
    uid = 310;
    port = 3100;
  };
  alloy = {
    uid = 62718;
    port = 12345;
  };
  restic = {
    uid = 291;
    port = 7100;
  };
  locksmith = {
    uid = 601;
  };
  reverse-tunnel = {
    uid = 602;
    port = 2602;
  };
  nix-build = {
    uid = 603;
    #port = 2603;
  };
  nix-switch = {
    uid = 604;
    #port = 2604;
  };
  nix-push = {
    uid = 605;
    #port = 2605;
  };
  tls-cert = {
    uid = 606;
    #port = 2606;
  };
  rspamd-redis = {
    uid = 612;
    port = 2612;
  };
  egress-proxy = {
    uid = 613;
    port = 2613;
  };
  collabora = {
    port = 9980;
  };
  admin = {
    uid = 1000;
  };
  test-redis = {
    uid = 614;
    port = 2614;
  };
}
