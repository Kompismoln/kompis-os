{
  lib,
  config,
  pkgs,
  ...
}:

let
  inherit (lib)
    filterAttrs
    mapAttrs
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.kompis-os.vd;
  eachUser = filterAttrs (user: cfg: cfg.enable) cfg;

  userOpts = {
    options.enable = mkEnableOption "Visual design tools for this user";
  };
in
{
  options.kompis-os.vd =
    with types;
    mkOption {
      description = "Set of users to be configured with visual design tools.";
      type = attrsOf (submodule userOpts);
      default = { };
    };

  config = mkIf (eachUser != { }) {
    home-manager.users = mapAttrs (user: cfg: { kompis-os-hm.vd.enable = true; }) eachUser;

    # Mirror at web.archive.org has stopped working, fix at some point
    #nixpkgs.config.allowUnfreePredicate =
    #  pkg: builtins.elem (lib.getName pkg) [ "helvetica-neue-lt-std" ];

    fonts.packages = with pkgs; [
      aileron
      barlow
      cabin
      dina-font
      dm-sans
      fira
      fira-code
      fira-code-symbols
      font-awesome
      garamond-libre
      # helvetica-neue-lt-std
      ibm-plex
      inter
      jost
      kanit-font
      libre-baskerville
      libre-bodoni
      libre-franklin
      liberation_ttf
      manrope
      mplus-outline-fonts.githubRelease
      montserrat
      noto-fonts
      noto-fonts-emoji
      oxygenfonts
      roboto
      roboto-mono
      roboto-slab
      roboto-serif
      paratype-pt-sans
      proggyfonts
      raleway
      redhat-official-fonts
      rubik
      source-sans-pro
      ubuntu_font_family
    ];
  };
}
