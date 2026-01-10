{
  config,
  home,
  host,
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
  cfg = config.kompis-os-hm.hyprland;
  host = org.host.${home.hostname};
in

{
  options.kompis-os-hm.hyprland = {
    enable = lib.mkEnableOption "hyprland et al";
  };

  imports = [
    ./foot.nix
  ];

  config = lib.mkIf cfg.enable {

    kompis-os-hm.foot.enable = true;

    xdg.mimeApps.enable = true;

    xdg.mimeApps.defaultApplications = {
      "text/*" = "nvim.desktop";
      "image/*" = "feh.desktop";
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

    programs.waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          spacing = 4;
          output = map (m: m.output) host.monitors;
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
          network = {
            "interface" = host.desktop.wifi-interface;
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
              "alsa_output.${host.desktop.audio-bus-id}.analog-stereo" = "";
              "alsa_output.${host.desktop.audio-bus-id}.analog-stereo-muted" = "";
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
        monitorv2 = host.monitors;

        exec-once = [
          "${lib.getExe pkgs.swaybg} -i ${config.home.file.wallpaper.target}"
          "${lib.getExe pkgs.waybar}"
        ];

        general = {
          gaps_out = 10;
        };

        input = {
          kb_layout = host.desktop.kb-layout;
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

        device = host.devices;

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
