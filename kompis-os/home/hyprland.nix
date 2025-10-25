{
  config,
  inputs,
  lib,
  lib',
  org,
  pkgs,
  ...
}:

let
  inherit (org.theme) fonts;
  colors = lib'.semantic-colors org.theme.colors;
  unhashedHexes = lib.mapAttrs (n: c: lib.substring 1 6 c) colors;
  cfg = config.kompis-os-hm.hyprland;
in

{
  options.kompis-os-hm.hyprland = {
    enable = lib.mkEnableOption "hyprland et al";
  };

  config = lib.mkIf cfg.enable {

    xdg.mimeApps.associations.added = {
      "text/*" = "nvim.desktop";
      "text/x-lua" = "nvim.desktop";
      "image/*" = "feh.desktop";
      "image/jpeg" = "feh.desktop";
      "video/*" = "mpv.desktop";
      "audio/*" = "mpv.desktop";
      "application/pdf" = "mupdf.desktop";
    };

    home.packages = with pkgs; [
      feh
      mpv
      mupdf
      pinta
      wl-clipboard
    ];

    home.file.wallpaper = {
      source = "${inputs.self}/${org.theme.wallpaper}";
      target = ".config/hypr/wallpaper.jpg";
    };

    programs.foot = {
      enable = true;
      settings = {
        main.font = "${fonts.monospace.name}:size=11";
        main.dpi-aware = "no";
        mouse.hide-when-typing = "yes";
        colors = with unhashedHexes; {
          alpha = 0.8;
          background = bg-300;
          foreground = fg-200;

          regular0 = base00;
          regular1 = base01;
          regular2 = base02;
          regular3 = base03;
          regular4 = base04;
          regular5 = base05;
          regular6 = base06;
          regular7 = base07;

          bright0 = base08;
          bright1 = base09;
          bright2 = base0A;
          bright3 = base0B;
          bright4 = base0C;
          bright5 = base0D;
          bright6 = base0E;
          bright7 = base0F;
        };
      };
    };

    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;
          output = [
            "eDP-1"
            "HDMI-A-1"
            "HDMI-A-2"
          ];
          modules-right = [
            "pulseaudio#source"
            "pulseaudio#sink"
            "bluetooth"
            "network"
            "battery"
          ];
          modules-left = [
            "hyprland/workspaces"
            "hyprland/submap"
          ];
          modules-center = [ "clock" ];
          "network" = {
            "interface" = "wlp1s0";
            "format" = "{ifname}";
            "format-wifi" = "{essid} ({signalStrength}%) ";
            "format-ethernet" = "{ipaddr}/{cidr} 󰊗";
            "format-disconnected" = "";
            "tooltip-format" = "{ifname} via {gwaddr} 󰊗";
            "tooltip-format-wifi" = "{essid} ({signalStrength}%) ";
            "tooltip-format-ethernet" = "{ifname} ";
            "tooltip-format-disconnected" = "Disconnected";
            "max-length" = 50;

          };
          "pulseaudio#source" = {
            "format-source" = "{volume}% ";
            "format-source-muted" = "{volume}% ";
            "format" = "{format_source}";
            "max-volume" = 100;
            "on-click" = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
            "on-click-middle" = "pavucontrol";
            "on-scroll-up" = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1%+";
            "on-scroll-down" = "wpctl set-volume @DEFAULT_AUDIO_SOURCE@ 1%-";
          };
          "pulseaudio#sink" = {
            "format" = "{volume}% {icon}";
            "format-bluetooth" = "{volume}% {icon}";
            "format-muted" = "";
            "format-icons" = {
              "alsa_output.pci-0000_00_1f.3.analog-stereo" = "";
              "alsa_output.pci-0000_00_1f.3.analog-stereo-muted" = "";
              "headphone" = "";
              "hands-free" = "";
              "headset" = "";
              "phone" = "";
              "phone-muted" = "";
              "portable" = "";
              "car" = "";
              "default" = [
                ""
                ""
              ];
            };
            "scroll-step" = 1;
            "on-click" = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
            "on-click-middle" = "pavucontrol";
            "ignored-sinks" = [ "Easy Effects Sink" ];
          };
          bluetooth = {
            format = " {status}";
            "format-connected" = " {device_alias}";
            "format-connected-battery" = " {device_alias} {device_battery_percentage}%";
            "tooltip-format" = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
            "tooltip-format-connected" =
              "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
            "tooltip-format-enumerate-connected" = "{device_alias}\t{device_address}";
            "tooltip-format-enumerate-connected-battery" =
              "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          };
          clock = {
            tooltip-format = "<tt><small>{calendar}</small></tt>";
            format-alt = "{:%A %Y-%m-%d}";
            calendar = {
              mode = "year";
              mode-mon-col = 3;
              weeks-pos = "left";
              format = with colors; {
                months = "<span color='${green-400}'><b>{}</b></span>";
                days = "<span color='${white-400}'><b>{}</b></span>";
                weeks = "<span color='${purple-400}'><b>{}</b></span>";
                weekdays = "<span color='${yellow-400}'><b>{}</b></span>";
                today = "<span color='${red-400}'><b><u>{}</u></b></span>";
              };
            };
          };
        };
      };
      style = with colors; ''
        * {
          font-family: ${fonts.monospace.name};
          background-color: ${bg-400};
        }

        #workspaces button.active {
          color: ${fg-300};
        }

        .module {
          padding: 0 10px;
          border-radius: 10px;
          background-color: ${bg-300};
          color: ${fg-300};
        }
      '';
    };

    programs.hyprlock = {
      enable = true;
      settings = {
        general = {
          ignore_empty_input = true;
          hide_cursor = true;
        };

        background = [
          {
            color = "#000000";
          }
        ];

        input-field = [
          {
            position = "0, 0";
            font-family = fonts.monospace.name;
          }
        ];
      };
    };

    wayland.windowManager.hyprland = {
      enable = true;
      settings = {
        monitor = [
          "eDP-1, 1366x768, 0x0, 1"
          "HDMI-A-2, 1920x1080, -1920x0, 1"
        ];
        exec-once =
          let
            uid = lib'.ids.${config.home.username}.uid;
            start-waybar = pkgs.writeShellScriptBin "start-waybar" ''
              while [ ! -S "/run/user/${toString uid}/hypr/''${HYPRLAND_INSTANCE_SIGNATURE}/.socket.sock" ]; do
                sleep 0.1
              done
              sleep 0.5
              ${lib.getExe pkgs.waybar}
            '';
          in
          [
            "${lib.getExe pkgs.swaybg} -i ${config.home.file.wallpaper.target}"
            "${start-waybar}/bin/start-waybar"
          ];

        general = {
          gaps_out = 10;
        };

        input = {
          kb_layout = "us,se";
          kb_options = "grp:caps_switch";
          repeat_rate = 35;
          repeat_delay = 175;
          follow_mouse = true;
          touchpad = {
            natural_scroll = true;
            tap-and-drag = true;
          };
        };

        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          disable_autoreload = true;
        };

        animations = {
          enabled = true;
          animation = [
            "global, 1, 5, default"
            "workspaces, 1, 1, default"
          ];
        };

        dwindle = {
          pseudotile = true;
          preserve_split = true;
        };

        device = [
          {
            name = "epic-mouse-v1";
            sensitivity = -0.5;
          }
          {
            name = "wacom-intuos-pt-m-pen";
            transform = 0;
            output = "HDMI-A-1";
          }
        ];

        windowrule = [
          "float, class:^(.*)$"
          "size 550 350, class:^(.*)$"
          "center, class:^(.*)$"
        ];
        "$mainMod" = "SUPER";

        bind =
          let
            e = lib.getExe;
            hyprctl = "${pkgs.hyprland}/bin/hyprctl";
            activeMonitor = "${hyprctl} monitors | ${e pkgs.gawk} '/Monitor/{mon=$2} /focused: yes/{print mon}'";
            workspaces = builtins.genList (x: x) 10;
          in
          with pkgs;
          [
            "$mainMod, i, exec, ${e foot}"
            "$mainMod, o, exec, ${e qutebrowser}"
            "$mainMod, r, exec, ${e fuzzel}"
            ''$mainMod, p, exec, ${e grim} -g "$(${e slurp})" - | ${e swappy} -f -''
            '', PRINT, exec, ${e grim} -o "$(${activeMonitor})" - | ${e swappy} -f -''
            "$mainMod, return, togglefloating,"
            "$mainMod, c, killactive,"
            "$mainMod, q, exit,"
            "$mainMod, d, pseudo,"
            "$mainMod, a, togglesplit,"
            "$mainMod, s, exec, systemctl suspend,"
            "$mainMod, h, movefocus, l"
            "$mainMod, l, exec, hyprlock"
            "$mainMod, k, movefocus, u"
            "$mainMod, j, cyclenext, hist"
            "$mainMod, mouse_down, workspace, e+1"
            "$mainMod, mouse_up, workspace, e-1"
          ]
          ++ map (i: "$mainMod, ${toString i}, workspace, ${toString i}") workspaces
          ++ map (i: "$mainMod SHIFT, ${toString i}, movetoworkspacesilent, ${toString i}") workspaces;

        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];
      };
    };
  };
}
