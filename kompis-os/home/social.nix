{
  config,
  lib,
  pkgs,
  ...
}:

{
  options.kompis-os-hm.social = {
    enable = lib.mkEnableOption "social tools";
  };

  config = lib.mkIf config.kompis-os-hm.social.enable {

    xdg.mimeApps.defaultApplications = {
      "message/rfc88" = "thunderbird.desktop";
      "application/x-email" = "thunderbird.desktop";
      "x-scheme-handler/mailto" = "thunderbird.desktop";
    };

    home.packages = with pkgs; [
      kooha
      signal-desktop-bin
      thunderbird
      neomutt
    ];
  };
}
