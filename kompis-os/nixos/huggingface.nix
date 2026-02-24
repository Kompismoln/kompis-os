# kompis-os/nixos/huggingface.nix
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.kompis-os.huggingface;
in
{
  options.kompis-os.huggingface = {
    enable = lib.mkEnableOption "the Hugging Face Hub CLI with configured cache directories";
    home = lib.mkOption {
      type = lib.types.str;
      default = config.users.users.huggingface.home;
      description = ''
        The path to use for the HF_HOME environment variable.
      '';
    };
    repo = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.home}/hub";
      example = "/srv/models/huggingface";
      description = ''
        The path to use for the HF_HUB_CACHE environment variable.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages =
      let
        huggingface-cli = pkgs.writeShellScriptBin "huggingface-cli" ''
          export HF_HOME=${cfg.home}
          export HF_HUB_CACHE=${cfg.repo}
          exec ${pkgs.python3Packages.huggingface-hub}/bin/huggingface-cli "$@"
        '';
        hf = pkgs.writeShellScriptBin "hf" ''
          export HF_HOME=${cfg.home}
          export HF_HUB_CACHE=${cfg.repo}
          exec ${pkgs.python3Packages.huggingface-hub}/bin/hf "$@"
        '';

      in
      [
        hf
        huggingface-cli
      ];

    kompis-os.paths.${cfg.repo}.user = "huggingface";
    kompis-os.users.huggingface.class = "store";
  };
}
