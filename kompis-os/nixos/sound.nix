# kompis-os/nixos/sound.nix
{
  pkgs,
  lib,
  config,
  ...
}:
{
  options.kompis-os.sound = {
    enable = lib.mkEnableOption "pipewire in compatibility mode";
  };

  config = lib.mkIf config.kompis-os.sound.enable {
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
      lib.filterAttrs (user: userCfg: userCfg.isNormalUser) config.users.users
    );
  };
}
