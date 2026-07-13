# nixos/org/huggingface.nix
{
  config,
  pkgs,
  ...
}:

let
  HF_HOME = config.users.users.huggingface.home;
  HF_HUB_CACHE = "/srv/models/huggingface/hub";
in
{
  imports = [ ../principals.nix ];
  kompis-os.principals.huggingface.class = "store";

  environment.systemPackages =
    let
      huggingface-cli = pkgs.writeShellScriptBin "huggingface-cli" ''
        export HF_HOME=${HF_HOME}
        export HF_HUB_CACHE=${HF_HUB_CACHE}
        exec ${pkgs.python3Packages.huggingface-hub}/bin/huggingface-cli "$@"
      '';
      hf = pkgs.writeShellScriptBin "hf" ''
        export HF_HOME=${HF_HOME}
        export HF_HUB_CACHE=${HF_HUB_CACHE}
        exec ${pkgs.python3Packages.huggingface-hub}/bin/hf "$@"
      '';

    in
    [
      hf
      huggingface-cli
    ];

  systemd.tmpfiles.rules = [
    "d '${HF_HUB_CACHE}' 0750 huggingface huggingface - -"
    "Z '${HF_HUB_CACHE}' 0750 huggingface huggingface - -"
  ];
}
