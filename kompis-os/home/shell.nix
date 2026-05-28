{
  config,
  lib,
  lib',
  pkgs,
  ...
}:

let
  cfg = config.kompis-os-hm.shell;
in

{
  options.kompis-os-hm.shell = {
    enable = lib.mkEnableOption "shell tools";
  };

  config = lib.mkIf cfg.enable {

    home.packages = (lib'.package-sets pkgs).all;

    programs = {
      readline = {
        enable = true;
        bindings = {
          "\\ee" = "edit-and-execute-command";
        };
      };
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
          f = "xdg-open \"$(${lib.getExe pkgs.fzf})\"";
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
          # Unbind fzf defaults
          bind -m emacs-standard -r '\C-t'
          bind -m emacs-standard -r '\C-r'
          bind -m emacs-standard -r '\ec'

          # Rebind fzf
          bind -x '"\er": __fzf_history__'

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
        tmux.enableShellIntegration = true;
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
        extraConfig = ''
          set -g allow-passthrough on
          set -g set-clipboard on

          set -g extended-keys on
          set -ga terminal-features 'xterm*:extkeys'

          set -g status-right "#{user}@#{host}"

          set -ga terminal-overrides ",256col:Tc"
          set -ga terminal-features ',foot:RGB'

          set -ga update-environment TERM
          set -ga update-environment TERM_PROGRAM
          set -ga update-environment SSH_AUTH_SOCK

          bind -n M-o new-window
          bind -n M-j next-window
          bind -n M-k previous-window
          bind -n M-c kill-pane

          bind -n M-x split-window -v -c "#{pane_current_path}"
          bind -n M-v split-window -h -c "#{pane_current_path}"

          bind -n M-p select-pane -t :.-
          bind -n M-n select-pane -t :.+

          bind -n M-y copy-mode

          bind -T copy-mode-vi y send -X copy-pipe-and-cancel '${pkgs.osc}/bin/osc copy'
        '';
      };

      yazi = {
        enable = true;
        shellWrapperName = "yy";
        enableBashIntegration = true;
      };

      zoxide = {
        enable = true;
      };
    };
  };
}
