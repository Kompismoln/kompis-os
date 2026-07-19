# tests/base.nix
{
  pkgs,
  o11nLib,
}:
let
  inherit (pkgs) lib;
  outputs = o11nLib.fromPath ./inventories/base;
in
lib.runTests {
  test_org_min = {
    expr = outputs.org.endpoint;
    expected = "example.com";
  };
  test_disko_min = {
    expr = outputs.diskoConfigurations;
    expected = { };
  };
  test_home_min = {
    expr = outputs.homeConfigurations;
    expected = { };
  };
  test_nixos_min = {
    expr = outputs.nixosConfigurations;
    expected = { };
  };
}
