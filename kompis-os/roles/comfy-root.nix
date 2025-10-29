{
  flake.nixosModules.comfy-root =
    { pkgs, ... }:
    {
      environment.systemPackages = with pkgs; [
        osc
        neovim
      ];
    };
}
