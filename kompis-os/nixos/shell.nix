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
    user: cfg:
    hasAttr user config.kompis-os.home-manager && config.kompis-os.home-manager.${user}.enable
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

    programs.bash.promptInit = builtins.readFile ../tools/session/prompt-init.sh;

    environment.systemPackages = with pkgs; [
      age
      envsubst
      git
      jq
      libxml2
      ssh-to-age
      sops
      w3m
      vim
      tree
      neomutt
      nixos-facter
      km-tools
      nix-serve-ng
    ];
  };
}
