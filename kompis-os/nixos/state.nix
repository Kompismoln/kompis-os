{
  config,
  lib,
  lib',
  pkgs,
  ...
}:
{
  options.kompis-os.state.enable = lib.mkEnableOption "restic state management";
  config = lib.mkIf config.kompis-os.state.enable (
    let
      eachUser = lib.filterAttrs (user: userCfg: userCfg.stateful) config.kompis-os.users;
      statePkg =
        user: userCfg:
        pkgs.runCommand "state"
          {
            buildInputs = [ pkgs.makeWrapper ];
          }
          ''
              mkdir -p $out/bin
              cp ${../tools/remote/state.sh} $out/bin/state-unwrapped
              chmod +x $out/bin/state-unwrapped
              makeWrapper $out/bin/state-unwrapped $out/bin/state \
                --prefix PATH : ${
                  lib.makeBinPath [
                    pkgs.restic
                  ]
                } \
            --set RESTIC_REPOSITORY "${config.users.users.${user}.home}/.restic" \
            --set RESTIC_PASSWORD_FILE "${config.sops.secrets."${user}/restic-key".path}"

          '';

      userMatchBlocks = lib.concatStringsSep "\n" (
        lib.mapAttrsToList (user: userCfg: ''
          Match User ${user}
            ForceCommand ${statePkg user userCfg}/bin/state
            AllowTcpForwarding no
            X11Forwarding no
            AllowAgentForwarding no
            PermitTunnel no
        '') eachUser
      );
    in
    {
      sops.secrets = lib.mapAttrs' (
        user: userCfg:
        lib.nameValuePair "${user}/restic-key" {
          sopsFile = lib'.secrets userCfg.class user;
          owner = user;
          group = user;
        }
      ) eachUser;

      users.users = lib.mapAttrs (user: userCfg: {
        packages = [ (statePkg user userCfg) ];
      }) eachUser;

      services.openssh = {
        extraConfig = userMatchBlocks;
      };
    }
  );
}
