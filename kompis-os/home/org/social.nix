{
  pkgs,
  ...
}:

{

  xdg.mimeApps.defaultApplications = {
    "message/rfc88" = "thunderbird.desktop";
    "application/x-email" = "thunderbird.desktop";
    "x-scheme-handler/mailto" = "thunderbird.desktop";
  };

  home.packages = with pkgs; [
    kooha
    signal-desktop
    thunderbird
    neomutt
  ];
}
