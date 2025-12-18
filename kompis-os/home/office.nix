# kompis-os/home/office.nix
{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.kompis-os-hm.office = {
    enable = lib.mkEnableOption "office";
  };

  config = lib.mkIf config.kompis-os-hm.office.enable {
    programs.firefox = {
      enable = true;
    };

    programs.chromium = {
      enable = true;
    };

    home.packages = with pkgs; [
      libreoffice
      gnome-system-monitor
      mate.mate-system-monitor
      xreader
      xournalpp
      zoom-us
      hunspell
      hunspellDicts.sv_SE
      hunspellDicts.en_US
    ];
  };
}
