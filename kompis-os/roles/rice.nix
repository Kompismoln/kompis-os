# kompis-os/roles/rice.nix
{
  inputs,
  ...
}:
let
  nmtui-themed =
    { pkgs, lib }:
    let
      newt_colors = rec {
        root = [
          "black"
          "black"
        ];
        roottext = [
          "brightmagenta"
          "black"
        ];
        window = roottext;
        border = roottext;
        shadow = roottext;
        title = roottext;
        label = roottext;
        helpline = roottext;
        emptyscale = roottext;
        fullscale = roottext;
        entry = [
          "white"
          "black"
        ];
        disentry = [
          "gray"
          "black"
        ];
        entrylabel = roottext;
        listbox = roottext;
        sellistbox = roottext;
        actlistbox = [
          "cyan"
          "black"
        ];
        actsellistbox = button;

        compactbutton = roottext;
        button = [
          "black"
          "magenta"
        ];
        actbutton = [
          "white"
          "magenta"
        ];
        textbox = roottext;
        acttextbox = button;
        checkbox = roottext;
        actcheckbox = button;
      };
      nmt_newt_colors = {
        plainLabel = [
          "cyan"
          "black"
        ];
        badLabel = [
          "red"
          "black"
        ];
        disabledButton = [
          "gray"
          "black"
        ];
        textboxWithBackground = [
          "yellow"
          "black"
        ];
      };
      newtColorsString = builtins.concatStringsSep ";" (
        lib.mapAttrsToList (name: value: "${name}=${builtins.concatStringsSep "," value}") newt_colors
      );
      nmtNewtColorsString = builtins.concatStringsSep ";" (
        lib.mapAttrsToList (name: value: "${name}=${builtins.concatStringsSep "," value}") nmt_newt_colors
      );
    in
    pkgs.writeShellScriptBin "nmtui" ''
      export NEWT_COLORS='${newtColorsString}'
      export NMT_NEWT_COLORS='${nmtNewtColorsString}'
      exec ${pkgs.networkmanager}/bin/nmtui "$@"
    '';
in
{
  flake.nixosModules.rice =
    { pkgs, ... }:
    {
      environment.systemPackages = [ (pkgs.callPackage nmtui-themed { }) ];
    };
  flake.homeModules.rice =
    { lib', lib, ... }:
    let
      inherit (inputs.self.org.theme) fonts;
      colors = lib'.semantic-colors;
      unhashedHexes = lib.mapAttrs (_: c: lib.substring 1 6 c) colors;
    in
    with colors;
    {
      wayland.windowManager.hyprland.settings = {
        decoration = {
          rounding = 6;
          dim_inactive = true;
        };
        general = {
          gaps_in = 5;
          gaps_out = 0;
          border_size = 0;
          "col.active_border" = "0xff${unhashedHexes.bg-light}";
          "col.inactive_border" = "0xff${unhashedHexes.bg-shade}";
        };
      };
      programs = {
        waybar = {
          style = with colors; ''
            window#waybar {
              font-family: ${fonts.monospace.name};
              background-color: ${bg-base};
            }

            #workspaces button.active {
              color: ${fg-bright};
              background-color: ${bg-shade};
            }

            #clock {
              font-family: ${fonts.serif.name};
              color: ${fg-dimmed};
              background-color: ${bg-base};
            }

            #workspaces {
              padding: 0 6px;
            }

            #workspaces button {
              margin: 3px 3px;
              padding: 0 10px;
              color: ${fg-dimmed};
              background-color: ${bg-base};
            }

            .module {
              padding: 0 12px;
              border-radius: 6px;
              background-color: ${bg-light};
              color: ${fg-bright};
            }
            .modules-right .module {
              font-family: ${fonts.sansSerif.name};
              font-size: 11px;
            }
          '';
          settings.mainBar = {
            clock.calendar = {
              format = with colors; {
                months = "<span color='${bright-green}'><b>{}</b></span>";
                days = "<span color='${regular-white}'><b>{}</b></span>";
                weeks = "<span color='${bright-yellow}'><b>{}</b></span>";
                weekdays = "<span color='${bright-cyan}'><b>{}</b></span>";
                today = "<span color='${bright-white}'><b><u>{}</u></b></span>";
              };
            };
          };
        };
        hyprlock.settings = {
          background = [
            {
              color = "#000000";
            }
          ];

          input-field = [
            {
              font-family = fonts.monospace.name;
            }
          ];
        };
        tmux.extraConfig = with colors; ''
          set -g status-bg "${bg-light}"
          set -g status-fg "${fg-dimmed}"
        '';
        foot.settings = {
          main.font = "${fonts.monospace.name}:size=11";
          colors-dark = with unhashedHexes; {
            alpha = 0.8;
            inherit background foreground;

            regular0 = regular-black;
            regular1 = regular-red;
            regular2 = regular-green;
            regular3 = regular-yellow;
            regular4 = regular-blue;
            regular5 = regular-magenta;
            regular6 = regular-cyan;
            regular7 = regular-white;

            bright0 = bright-black;
            bright1 = bright-red;
            bright2 = bright-green;
            bright3 = bright-yellow;
            bright4 = bright-blue;
            bright5 = bright-magenta;
            bright6 = bright-cyan;
            bright7 = bright-white;
          };
        };
        qutebrowser.settings = {
          fonts = {
            default_family = [ fonts.monospace.name ];
            default_size = "11pt";
            hints = "default_size default_family";
          };
          hints.border = "1px solid ${bg-base}";
          colors = {
            completion = {
              category = {
                bg = bg-light;
                border.bottom = bg-light;
                border.top = bg-light;
                fg = fg-bright;
              };
              even.bg = bg-base;
              odd.bg = bg-shade;
              fg = fg-base;
              item.selected = {
                bg = bg-selected;
                border.bottom = bg-selected;
                border.top = bg-selected;
                fg = fg-selected;
                match.fg = fg-match-selected;
              };
              match.fg = fg-match;
              scrollbar.bg = bg-shade;
              scrollbar.fg = fg-dimmed;
            };
            contextmenu = {
              disabled.bg = bg-disabled;
              disabled.fg = fg-disabled;
              menu.bg = bg-base;
              menu.fg = fg-base;
              selected.bg = bg-selected;
              selected.fg = fg-selected;
            };
            downloads = {
              bar.bg = bg-base;
              error.bg = bg-error;
              error.fg = fg-error;
              start.bg = bg-base;
              start.fg = fg-base;
              stop.bg = bg-success;
              stop.fg = fg-success;
              system.bg = "rgb";
              system.fg = "rgb";
            };
            hints = {
              bg = bg-hint;
              fg = fg-hint;
              match.fg = fg-match;
            };
            keyhint = {
              bg = bg-hint;
              fg = fg-hint;
              suffix.fg = fg-match;
            };
            messages = {
              error = {
                bg = bg-error;
                border = bg-error;
                fg = fg-error;
              };
              info = {
                bg = bg-info;
                border = bg-info;
                fg = fg-info;
              };
              warning = {
                bg = bg-warning;
                border = bg-warning;
                fg = fg-warning;
              };
            };
            prompts = {
              bg = bg-base;
              border = bg-base;
              fg = fg-base;
              selected.bg = bg-selected;
              selected.fg = fg-selected;
            };
            statusbar = {
              caret = {
                bg = bg-base;
                fg = fg-base;
                selection.bg = bg-base;
                selection.fg = fg-base;
              };
              command = {
                bg = bg-base;
                fg = fg-base;
                private.bg = bg-base;
                private.fg = fg-base;
              };
              insert.bg = bg-base;
              insert.fg = fg-base;
              normal.bg = bg-base;
              normal.fg = fg-base;
              passthrough.bg = bg-base;
              passthrough.fg = fg-base;
              private.bg = bg-base;
              private.fg = fg-base;
              progress.bg = bg-base;
              url = {
                error.fg = fg-error;
                fg = fg-base;
                hover.fg = fg-base;
                success.http.fg = fg-dimmed;
                success.https.fg = fg-bright;
                warn.fg = fg-warning;
              };
            };

            tabs = {
              bar.bg = bg-base;
              even.bg = bg-base;
              even.fg = fg-dimmed;
              indicator = {
                error = bg-error;
                start = bg-info;
                stop = bg-base;
                system = "rgb";
              };
              odd.bg = bg-base;
              odd.fg = fg-dimmed;
              pinned = {
                even.bg = bg-base;
                even.fg = regular-cyan;
                odd.bg = bg-base;
                odd.fg = regular-cyan;
                selected = {
                  even.bg = bg-base;
                  even.fg = bright-cyan;
                  odd.bg = bg-base;
                  odd.fg = bright-cyan;
                };
              };
              selected = {
                even.bg = bg-shade;
                even.fg = fg-bright;
                odd.bg = bg-shade;
                odd.fg = fg-bright;
              };
            };
            tooltip = {
              bg = bg-base;
              fg = fg-base;
            };
          };
        };
        nixvim = {
          colorschemes.cyberdream.enable = true;
          colorschemes.cyberdream.settings.highlights = lib.mapAttrs (
            _group: groupCfg:
            groupCfg
            // lib.genAttrs (lib.filter (f: groupCfg ? ${f}) [
              "fg"
              "bg"
              "sp"
            ]) (f: colors.${groupCfg.${f}})
          ) (fromTOML (builtins.readFile ../lib/vim-highlights.toml));
        };
      };
    };
}
