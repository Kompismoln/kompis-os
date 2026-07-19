# nixos/org/sound.nix
{
  pkgs,
  lib,
  config,
  ...
}:
{
  environment.systemPackages = with pkgs; [
    pavucontrol
  ];

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
  };

  security = {
    polkit.enable = true;
    rtkit.enable = true;
  };

  users.groups.pipewire.members = lib.attrNames (
    lib.filterAttrs (_user: userCfg: userCfg.isNormalUser) config.users.users
  );
}
