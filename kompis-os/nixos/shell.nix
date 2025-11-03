{
  config,
  inputs,
  lib,
  lib',
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

    nixpkgs.overlays = [
      (import ../overlays/km-tools.nix { inherit inputs; })
    ];

    programs.bash.promptInit = builtins.readFile ../tools/session/prompt-init.sh;

    programs.neovim = {
      enable = true;
      defaultEditor = true;
      vimAlias = true;
      viAlias = true;
      configure = {
        customRC = ''
          colorscheme vim
        '';
      };
    };

    environment.systemPackages = (lib'.package-sets pkgs).all;
  };
}
