{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    inputs.nixos-cli.nixosModules.nixos-cli
  ];

  options.kompis-os.shell = {
    enable = lib.mkEnableOption "shell tools";
  };

  config = lib.mkIf (config.kompis-os.shell.enable) {

    environment.sessionVariables = {
      SOPS_AGE_KEY_FILE = "/keys/user-$USER";
    };

    programs.bash.promptInit = builtins.readFile ../tools/session/prompt-init.sh;

    programs.neovim = {
      enable = true;
      defaultEditor = true;
    };

    environment.systemPackages = with pkgs; [
      age
      envsubst
      git
      jq
      libxml2
      ssh-to-age
      sops
      w3m
      tree
      nixos-facter
      km-tools
      nix-serve-ng
    ];
  };
}
