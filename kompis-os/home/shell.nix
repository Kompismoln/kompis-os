{
  config,
  lib,
  lib',
  org,
  pkgs,
  ...
}:

let
  colors = lib'.semantic-colors org.theme.colors;
  cfg = config.kompis-os-hm.shell;
in

{
  options.kompis-os-hm.shell = {
    enable = lib.mkEnableOption "shell tools";
  };

  config = lib.mkIf cfg.enable {

    home.packages = with pkgs; [
      bat
      bitwarden-cli
      btrfs-progs
      dig
      eza
      fd
      ffmpeg
      imagemagick
      inotify-tools
      iproute2
      nethogs
      nmap
      openssl
      ranger
      rdfind
      ripgrep
      tcpdump
      traceroute
      unzip
      which
      wireguard-tools
      xdg-utils
    ];

    programs = {
      bash = {
        enable = true;

        sessionVariables = {
          PATH = "$HOME/.local/bin:$PATH";
          PROMPT_COMMAND = "\${PROMPT_COMMAND:+$PROMPT_COMMAND; }history -a; history -c; history -r";
          HISTTIMEFORMAT = "%y-%m-%d %T ";
          MANPAGER = "sh -c 'col -bx | bat -l man -p'";
          MANROFFOPT = "-c";
        };

        shellAliases = {
          battery = "cat /sys/class/power_supply/BAT/capacity && cat /sys/class/power_supply/BAT/status";
          f = "xdg-open \"$(fzf)\"";
          l = "eza -la --icons=auto";
          ll = "eza";
          cd = "z";
          grep = "grep --color=auto";
          dirty-ssh = "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o GlobalKnownHostsFile=/dev/null";
          needs-reboot =
            let
              booted = "<(readlink /run/booted-system/{initrd,kernel,kernel-modules})";
              current = "<(readlink /run/current-system/{initrd,kernel,kernel-modules})";
              diff = "$(diff ${booted} ${current})";
            in
            ''if [[ ${diff} ]] then echo "yes"; else echo "no"; fi'';
        };

        historyControl = [
          "ignoredups"
          "erasedups"
          "ignorespace"
        ];

        shellOptions = [
          "histappend"
          "histverify"
          "checkwinsize"
          "extglob"
          "globstar"
          "checkjobs"
        ];

        initExtra = ''
          pwu() {
            bw unlock --raw > ~/.bwsession
          }
          pw() {
            BW_SESSION=$(<~/.bwsession) bw get password $@ | wl-copy
          }
          d() {
            ${lib.getExe pkgs.wdiff} "$1" "$2" | ${lib.getExe pkgs.colordiff}
          }
        '';
      };

      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };

      fzf = {
        enable = true;
      };

      ssh = {
        enable = true;
        enableDefaultConfig = false;
      };

      tmux = {
        enable = true;
        terminal = "tmux-256color";
        keyMode = "vi";
        escapeTime = 10;
        baseIndex = 1;
        extraConfig = with colors; ''
          set -g update-environment "SSH_AUTH_SOCK"
          set-option -ga terminal-features ',foot:RGB'
          set-option -g status-right "#{user}@#{host}"
          set -ga terminal-overrides ",256col:Tc"
          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM
          set -g allow-passthrough on
          set -g status-bg "${bg-400}"
          set -g status-fg "${fg-500}"
          bind -T copy-mode-vi y send -X copy-pipe-and-cancel 'wl-copy'
        '';
      };

      yazi = {
        enable = true;
        enableBashIntegration = true;
      };

      zoxide = {
        enable = true;
      };
    };
  };
}
