{ pkgs, ... }:
{
  home.packages = with pkgs; [
    webcamoid
    libcamera
    shotwell
  ];
}
