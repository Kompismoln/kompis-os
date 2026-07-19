{
  pkgs,
  ...
}:
{
  home.packages = with pkgs; [
    chromium
    firefox
    nyxt
  ];
}
