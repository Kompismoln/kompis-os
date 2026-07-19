# tests/default.nix
{
  pkgs,
  o11nLib,
}:
let
  inherit (pkgs) lib;
  baseOrg = o11nLib.mkOrgFlake { path = ./inventories/base; };
  kompismolnOrg = o11nLib.mkOrgFlake (
    let
      flake = builtins.getFlake (toString /home/alex/Desktop/org);
    in
    {
      inherit flake;
      path = flake.outPath;
    }
  );
in
lib.runTests {
  test_org_kompismoln = {
    expr = kompismolnOrg.org.endpoint;
    expected = "kompismoln.se";
  };
  test_disko_kompismoln = {
    expr = lib.attrNames (o11nLib.mkDiskoConfigurations kompismolnOrg.flake.inputs kompismolnOrg.org);
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
    expr = lib.attrNames (o11nLib.mkHomeConfigurations kompismolnOrg.flake.inputs kompismolnOrg.org);
    expected = [
      "alex@laptop"
      "alex@lenovo"
      "alex@pelle"
      "ami@adele"
    ];
  };
  test_nixos_kompismoln = {
    expr = lib.attrNames (o11nLib.mkNixosConfigurations kompismolnOrg.flake.inputs kompismolnOrg.org);
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
    expr =
      (o11nLib.mkNixosConfigurations kompismolnOrg.flake.inputs kompismolnOrg.org)
      .stationary.config.kompis-os.django.apps.chatddx-dev.package.name;
    expected = "chatddx-django-de86a39";
  };
  test_nixos_kompismoln_vim_highlights = {
    expr =
      (o11nLib.mkHomeConfigurations kompismolnOrg.flake.inputs kompismolnOrg.org)
      ."alex@lenovo".config.programs.nixvim.colorschemes.cyberdream.settings.highlights.Normal.bg;
    expected = "#0a0a0a";
  };
  test_nixos_kompismoln_nix_self_path = {
    expr = builtins.pathExists (o11nLib.mkNixosConfigurations kompismolnOrg.inputs kompismolnOrg.org)
      .lenovo.config.nix.registry.self.flake.outPath;
    expected = true;
  };
  test_nixos_kompismoln_pelle_wifi = {
    expr =
      (o11nLib.mkNixosConfigurations kompismolnOrg.inputs kompismolnOrg.org)
      .pelle.config.systemd.network.networks."10-wlp4s0".dhcpV4Config.RouteMetric;
    expected = 2048;
  };
  test_org_min = {
    expr = baseOrg.org.endpoint;
    expected = "example.com";
  };
  test_disko_min = {
    expr = o11nLib.mkDiskoConfigurations baseOrg.flake.inputs baseOrg.org;
    expected = { };
  };
  test_home_min = {
    expr = o11nLib.mkHomeConfigurations baseOrg.flake.inputs baseOrg.org;
    expected = { };
  };
  test_nixos_min = {
    expr = o11nLib.mkNixosConfigurations baseOrg.flake.inputs baseOrg.org;
    expected = { };
  };
}
