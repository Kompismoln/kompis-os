# tests/postfix-transport.nix
{ pkgs, ... }:

pkgs.testers.nixosTest {
  name = "postfix-transport-map";

  nodes.machine =
    { config, pkgs, ... }:
    {
      imports = [ ../modules/mailserver.nix ]; # whatever module actually sets this up
      # only the config needed to trigger transport-map generation, nothing else
    };

  testScript = ''
    machine.wait_for_unit("multi-user.target")

    expected = "example.com smtp:\nfoo.bar smtp:\n"
    actual = machine.succeed("cat /etc/postfix/transport")

    assert actual == expected, (
        f"transport file mismatch:\n--- expected ---\n{expected!r}\n--- actual ---\n{actual!r}"
    )
  '';
}
