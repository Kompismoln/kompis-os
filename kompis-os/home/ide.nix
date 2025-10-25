{
  config,
  lib,
  org,
  pkgs,
  ...
}:

{
  options.kompis-os-hm.ide = {
    enable = lib.mkEnableOption "IDE";
  };

  config = lib.mkIf config.kompis-os-hm.ide.enable {

    kompis-os-hm.neovim.enable = true;

    home.packages = with pkgs; [
      (sqlite.override { interactive = true; })
      sqlitebrowser
      xh
      bats
    ];

    programs.git = rec {
      enable = true;
      userName = config.home.username;
      userEmail = org.user.${userName}.email;
    };
  };
}
