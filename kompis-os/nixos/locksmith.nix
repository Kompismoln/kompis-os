# kompis-os/nixos/locksmith.nix
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.kompis-os.locksmith;

  locksmithPkg =
    pkgs.runCommand "locksmith"
      {
        buildInputs = [ pkgs.makeWrapper ];
      }
      ''
        mkdir -p $out/bin
        cp ${../tools/remote/locksmith.sh} $out/bin/locksmith-unwrapped
        chmod +x $out/bin/locksmith-unwrapped

        makeWrapper $out/bin/locksmith-unwrapped $out/bin/locksmith \
          --prefix PATH : ${
            lib.makeBinPath [
              pkgs.cryptsetup
              pkgs.age
            ]
          } \
          --set LUKS_DEVICE "${cfg.luksDevice}" \
          --set KEY_FILE "${config.sops.age.keyFile}"
      '';
in
{
  options.kompis-os.locksmith = {
    enable = lib.mkEnableOption "service locksmith";
    luksDevice = lib.mkOption {
      type = lib.types.str;
      default = "/dev/null";
    };
  };

  config = lib.mkIf (cfg.enable) {
    environment.systemPackages = [ locksmithPkg ];

    kompis-os.users.locksmith = {
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
  };
}
