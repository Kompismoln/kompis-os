{
  config,
  lib,
  lib',
  org,
  ...
}:

let
  inherit (org.theme) fonts;
  colors = lib'.semantic-colors org.theme.colors;
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
        config.bind('h', 'history')
        config.bind('x', 'tab-close')
        config.bind('<Ctrl-O>', 'back')
        config.bind('<Ctrl-I>', 'forward')
      '';
      settings = with colors; {
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
          javascript.clipboard = "access";
          pdfjs = true;
          cache = {
            appcache = true;
            maximum_pages = 7;
          };
        };
        fonts = {
          default_family = [ fonts.monospace.name ];
          default_size = "11pt";
          hints = "default_size default_family";
        };
        hints.border = "1px solid ${bg-400}";
        colors = {
          completion = {
            category = {
              bg = bg-300;
              border.bottom = bg-300;
              border.top = bg-300;
              fg = fg-300;
            };
            even.bg = bg-400;
            fg = fg-400;
            item.selected = {
              bg = bg-selected;
              border.bottom = bg-selected;
              border.top = bg-selected;
              fg = fg-selected;
              match.fg = fg-match-selected;
            };
            match.fg = fg-match;
            odd.bg = bg-500;
            scrollbar.bg = bg-500;
            scrollbar.fg = fg-500;
          };
          contextmenu = {
            disabled.bg = bg-disabled;
            disabled.fg = fg-disabled;
            menu.bg = bg-400;
            menu.fg = fg-400;
            selected.bg = bg-selected;
            selected.fg = fg-selected;
          };
          downloads = {
            bar.bg = bg-400;
            error.bg = bg-error;
            error.fg = fg-error;
            start.bg = bg-400;
            start.fg = fg-400;
            stop.bg = bg-success;
            stop.fg = fg-success;
            system.bg = "rgb";
            system.fg = "rgb";
          };
          hints = {
            bg = bg-400;
            fg = fg-400;
            match.fg = fg-match;
          };
          keyhint = {
            bg = bg-400;
            fg = fg-400;
            suffix.fg = fg-match;
          };
          messages = {
            error.bg = bg-error;
            error.border = bg-error;
            error.fg = fg-error;
            info.bg = bg-info;
            info.border = bg-info;
            info.fg = fg-info;
            warning.bg = bg-warning;
            warning.border = bg-warning;
            warning.fg = fg-warning;
          };
          prompts = {
            bg = bg-400;
            border = bg-400;
            fg = fg-400;
            selected.bg = bg-selected;
            selected.fg = fg-selected;
          };
          statusbar = {
            caret.bg = bg-400;
            caret.fg = fg-400;
            caret.selection.bg = bg-400;
            caret.selection.fg = fg-400;
            command.bg = bg-400;
            command.fg = fg-400;
            command.private.bg = bg-400;
            command.private.fg = fg-400;
            insert.bg = bg-400;
            insert.fg = fg-400;
            normal.bg = bg-400;
            normal.fg = fg-400;
            passthrough.bg = bg-400;
            passthrough.fg = fg-400;
            private.bg = bg-400;
            private.fg = fg-400;
            progress.bg = bg-400;
            url.error.fg = fg-error;
            url.fg = fg-400;
            url.hover.fg = fg-400;
            url.success.http.fg = fg-success;
            url.success.https.fg = fg-success;
            url.warn.fg = fg-warning;
          };

          tabs = {
            bar.bg = bg-400;
            even.bg = bg-400;
            even.fg = fg-400;
            indicator = {
              error = bg-error;
              start = bg-info;
              stop = bg-success;
              system = "rgb";
            };
            odd.bg = bg-400;
            odd.fg = fg-400;
            pinned = {
              even.bg = bg-500;
              even.fg = fg-500;
              odd.bg = bg-500;
              odd.fg = fg-500;
              selected = {
                even.bg = bg-selected;
                even.fg = fg-selected;
                odd.bg = bg-selected;
                odd.fg = fg-selected;
              };
            };
            selected = {
              even.bg = bg-selected;
              even.fg = fg-selected;
              odd.bg = bg-selected;
              odd.fg = fg-selected;
            };
          };
          tooltip = {
            bg = bg-400;
            fg = fg-400;
          };
        };
      };
    };
  };
}
