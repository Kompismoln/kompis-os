{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    hasAttr
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.kompis-os.shell;
  eachUser = filterAttrs (user: cfg: cfg.enable) cfg;
  eachHMUser = filterAttrs (
    user: cfg: hasAttr user config.kompis-os.hm && config.kompis-os.hm.${user}.enable
  ) eachUser;

  userOpts = {
    options.enable = mkEnableOption "shell for this user";
  };
in
{
  imports = [
    inputs.nixos-cli.nixosModules.nixos-cli
  ];

  options.kompis-os.shell =
    with types;
    mkOption {
      description = "Set of users to be configured with shell";
      type = attrsOf (submodule userOpts);
      default = { };
    };

  config = mkIf (eachUser != { }) {

    home-manager.users = mapAttrs (user: cfg: { kompis-os-hm.shell.enable = true; }) eachHMUser;

    environment.sessionVariables = {
      SOPS_AGE_KEY_FILE = "/keys/user-$USER";
    };

    # This takes too long time to be worth it
    # enable only when needed or update manually
    #documentation.man.generateCaches = true;

    services.nixos-cli = {
      enable = true;
    };
    programs.bash.promptInit = builtins.readFile ../tools/session/prompt-init.sh;

    environment.systemPackages = with pkgs; [
      envsubst
      jq
      yq-go
      ssh-to-age
      sops
      age
      w3m
      git
      vim
      tree
      neomutt
      nixos-facter
      km-tools
      nix-serve-ng
    ];
  };
}
