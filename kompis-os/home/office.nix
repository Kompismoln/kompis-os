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

    home.packages = with pkgs; [
      libreoffice
      hunspell
      hunspellDicts.sv_SE
      hunspellDicts.en_US
    ];
  };
}
