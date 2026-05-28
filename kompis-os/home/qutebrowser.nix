{
  config,
  lib,
  ...
}:

let
  cfg = config.kompis-os-hm.qutebrowser;
in

{
  options.kompis-os-hm.qutebrowser = {
    enable = lib.mkEnableOption "qutebrowser";
  };

  config = lib.mkIf cfg.enable {

    xdg.mimeApps.defaultApplications = {
      "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
      "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
    };

    programs.qutebrowser = {
      enable = true;
      extraConfig = ''
        c.url.searchengines = {'DEFAULT': 'https://ecosia.org/search?q={}'}
        config.unbind('<Ctrl-W>')
        config.unbind('D')
        config.unbind('d')
        config.bind('H', 'history')
        config.bind('B', 'cmd-set-text -s :tab-select')
        config.bind('C', 'tab-close')
        config.bind('<Ctrl-O>', 'back')
        config.bind('<Ctrl-I>', 'forward')
      '';
      settings = {
        input = {
          links_included_in_focus_chain = false;
        };
        search = {
          incremental = false;
        };
        url = {
          start_pages = [ "qute://history/" ];
          default_page = "qute://history/";
        };
        content = {
          javascript.clipboard = "access-paste";
          pdfjs = true;
          cache = {
            appcache = true;
            maximum_pages = 7;
          };
        };
      };
    };
  };
}
