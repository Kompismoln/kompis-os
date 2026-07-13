{
  config,
  org,
  pkgs,
  ...
}:

{
  imports = [
    ./neovim.nix
  ];

  home.packages = with pkgs; [
    (sqlite.override { interactive = true; })
    sqlitebrowser
  ];

  programs.git = {
    enable = true;
    settings.user = rec {
      name = config.home.username;
      email = org.user.${name}.email;
    };
  };
}
