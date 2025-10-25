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

  esse = {
    uid = 607;
    #port = 2607;
  };
  esse-redis = {
    uid = 608;
    port = 2608;
  };
  alex = {
    uid = 1001;
  };
  johanna = {
    uid = 1102;
  };
  ludvig = {
    uid = 1103;
  };
  ami = {
    uid = 1104;
  };
  klimatkalendern = {
    uid = 700;
    port = 2700;
  };
  klimatkalendern-dev = {
    uid = 701;
    port = 2701;
  };
  nextcloud-kompismoln = {
    uid = 702;
    port = 2702;
  };
  chatddx-redis = {
    uid = 610;
    port = 2610;
  };
  chatddx-svelte = {
    uid = 611;
    port = 2611;
  };
  chatddx-django = {
    uid = 609;
    port = 2609;
  };
  test-redis = {
    uid = 614;
    port = 2614;
  };
}
