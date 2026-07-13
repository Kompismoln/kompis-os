# kompis-os/nixos/org/locksmith.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  locksmithPkg =
    pkgs.runCommand "locksmith"
      {
        buildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        cp ${../../tools/remote/locksmith.sh} $out/bin/locksmith-unwrapped
        chmod +x $out/bin/locksmith-unwrapped

        makeWrapper $out/bin/locksmith-unwrapped $out/bin/locksmith \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.cryptsetup
              pkgs.age
            ]
          } \
          --set KEY_FILE "${config.sops.age.keyFile}"
      '';
in
{
  imports = [ ../principals.nix ];
  environment.systemPackages = [ locksmithPkg ];

  kompis-os.principals.locksmith = {
    class = "service";
    shell = true;
  };

  services.openssh = {
    extraConfig = ''
      Match User locksmith
        ForceCommand sudo ${locksmithPkg}/bin/locksmith \$SSH_ORIGINAL_COMMAND
    '';
  };

  security.sudo.extraRules = [
    {
      users = [ "locksmith" ];
      commands = [
        {
          command = "${locksmithPkg}/bin/locksmith *";
          options = [ "NOPASSWD" ];
        }
      ];
    }
  ];
}
