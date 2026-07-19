# tests/kompismoln.nix
{
  pkgs,
  o11nLib,
}:
let
  inherit (pkgs) lib;

  flake = builtins.getFlake (toString /home/alex/Desktop/org);

  outputs = o11nLib.fromFlake flake;

  diskoCfgs = outputs.diskoConfigurations;
  homeCfgs = outputs.homeConfigurations;
  nixosCfgs = outputs.nixosConfigurations;
in
lib.runTests {
  test_endpoint = {
    expr = outputs.org.endpoint;
    expected = "kompismoln.se";
  };
  test_disko = {
    expr = lib.attrNames diskoCfgs;
    expected = [
      "adele-main"
      "helsinki-main"
      "laptop-main"
      "pelle-main"
      "stationary-main"
      "stationary-single-xfs"
      "stationary-tungsten"
    ];
  };
  test_home_kompismoln = {
    expr = lib.attrNames homeCfgs;
    expected = [
      "alex@laptop"
      "alex@lenovo"
      "alex@pelle"
      "ami@adele"
    ];
  };
  test_nixos_kompismoln = {
    expr = lib.attrNames nixosCfgs;
    expected = [
      "adele"
      "bootstrap"
      "friday"
      "helsinki"
      "laptop"
      "lenovo"
      "pelle"
      "stationary"
    ];
  };
  test_nixos_kompismoln_chatddx = {
    expr = nixosCfgs.stationary.config.o11n.django.apps.chatddx-dev.package.name;
    expected = "chatddx-django-de86a39";
  };
  test_nixos_kompismoln_vim_highlights = {
    expr =
      homeCfgs."alex@lenovo".config.programs.nixvim.colorschemes.cyberdream.settings.highlights.Normal.bg;
    expected = "#0a0a0a";
  };
  test_nixos_kompismoln_nix_self_path = {
    expr = builtins.pathExists nixosCfgs.lenovo.config.nix.registry.self.flake.outPath;
    expected = true;
  };
  test_nixos_kompismoln_pelle_wifi = {
    expr = nixosCfgs.pelle.config.systemd.network.networks."10-wlp4s0".dhcpV4Config.RouteMetric;
    expected = 2048;
  };
}
