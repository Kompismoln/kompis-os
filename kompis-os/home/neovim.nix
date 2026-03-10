{
  config,
  inputs,
  lib,
  org,
  pkgs,
  ...
}:

let
  inherit (org.theme) colors;
in
{
  options.kompis-os-hm.neovim = {
    enable = lib.mkEnableOption "neovim";
  };

  imports = [
    inputs.nixvim.homeModules.nixvim
  ];

  config = lib.mkIf config.kompis-os-hm.neovim.enable {

    home.packages = with pkgs; [
      nixfmt
      ruff
      shellcheck
      shellharden
      shfmt
      bash-language-server
    ];

    programs.nixvim = {
      enable = true;
      vimAlias = true;
      colorschemes.kanagawa = {
        enable = true;
        settings = {
          transparent = false;
          colors.palette = with colors; {
            katanaGray = black-100; # deprecated
            fujiGray = black-200; # syn.comment term:bright black
            sumiInk6 = black-300; # nontext whitespace
            sumiInk5 = black-400; # bg_p2
            sumiInk4 = black-500; # bg_gutter bg_p1
            sumiInk3 = black-600; # bg
            sumiInk2 = black-700; # bg_m1
            sumiInk1 = black-800; # bg_dim bg_m2
            sumiInk0 = black-900; # bg_m3 float.bf float.fg_border float.bg_border term:black

            peachRed = red-300; # syn.special3 term:ext2
            autumnRed = red-400; # vcs.removed term:red
            samuraiRed = red-500; # diag.error term:bright red

            sakuraPink = pink-300; # syn.number
            waveRed = pink-400; # syn.preproc syn.special2
            winterRed = pink-500; # diff.delete

            springGreen = green-300; # syn.string diag.ok term:bright green
            autumnGreen = green-400; # vcs.added term:green
            winterGreen = green-500; # diff.add

            carpYellow = yellow-300; # syn.identifier term:bright yellow
            autumnYellow = yellow-400; # vcs.changed
            roninYellow = yellow-500; # diag.warning

            winterYellow = beige-500; # diff.text
            boatYellow1 = beige-400;
            boatYellow2 = beige-300; # syn.operator syn.regex term:yellow

            surimiOrange = orange-400; # syn.constant term:ext1

            lightBlue = blue-200; # syn.preproc?
            springBlue = blue-300; # syn.special1 term:bright blue
            crystalBlue = blue-400; # syn.fun term:blue
            waveBlue2 = blue-500; # bg_search pmenu.bg_sel pmenu.bg_thumb
            waveBlue1 = blue-600; # fg_reverse bg_visual pmenu.bg pmenu.bg_sbar
            winterBlue = blue-700; # diff.change

            oniViolet2 = purple-200; # syn.parameter
            springViolet1 = purple-300; # special term: bright magenta
            springViolet2 = purple-400; # syn.punct
            oniViolet = purple-500; # syn.statement syn.keyword term:magenta

            waveAqua2 = cyan-300; # syn.type term:bright cyan
            waveAqua1 = cyan-400; # diag.hint term:cyan
            dragonBlue = cyan-500; # diag.info

            oldWhite = white-500; # fg_dim float.fg term:white
            fujiWhite = white-400; # fg pmenu.fg term:bright white
          };
        };
      };

      globals.mapleader = "\\";

      opts = {
        number = true;
        shiftwidth = 2;
        tabstop = 2;
        expandtab = true;
        wildmenu = true;
        wildmode = "longest:full,full";
        foldmethod = "expr";
        foldexpr = "nvim_treesitter#foldexpr()";
        foldenable = false;
      };

      keymaps = [
        {
          key = "<C-j>";
          action = "<C-e>";
          options.desc = "Scroll down one line";
        }
        {
          key = "<C-k>";
          action = "<C-y>";
          options.desc = "Scroll up one line";
        }
        {
          key = "s";
          action = "<Plug>(leap-forward)";
          options.desc = "Open parent directory";
        }
        {
          key = "gs";
          action = "<Plug>(leap-from-window)";
          options.desc = "Open parent directory";
        }
        {
          key = "s";
          action = "<Plug>(leap-forward)";
          options.desc = "Open parent directory";
        }
        {
          key = "gs";
          action = "<Plug>(leap-from-window)";
          options.desc = "Open parent directory";
        }
        {
          key = "S";
          action = "<Plug>(leap-backward)";
          options.desc = "Open parent directory";
        }
        {
          key = "-";
          action = "<cmd>Oil<cr>";
          options.desc = "Open parent directory";
        }
        {
          key = "<F2>";
          action = "<cmd>NvimTreeToggle<cr>";
        }
        {
          key = "<leader>sh";
          action = ":split<cr>";
        }
        {
          key = "<leader>sv";
          action = ":vsplit<cr>";
        }
        {
          key = "<leader>y";
          action = ''"+yy'';
          mode = [ "n" ];
        }
        {
          key = "<leader>y";
          action = ''"+y'';
          mode = [ "v" ];
        }
        {
          key = "<leader>bn";
          action = ":bnext<cr>";
          options.desc = "Next buffer";
        }
        {
          key = "<leader>bp";
          action = ":bprevious<cr>";
          options.desc = "Previous buffer";
        }
        {
          key = "<leader>w";
          action = ":w<cr>";
          options.desc = "Save file";
        }
        {
          key = "<leader>f";
          action.__raw = ''
            function()
              require("conform").format({ async = true, lsp_fallback = true })
            end
          '';
          options.desc = "Format buffer";
        }
        {
          key = "<leader>tf";
          action.__raw = ''
            function()
              vim.g.disable_autoformat = not vim.g.disable_autoformat
              print("Autoformat " .. (vim.g.disable_autoformat and "disabled" or "enabled"))
            end
          '';
          mode = "n";
          options.desc = "Toggle autoformat";
        }

        {
          key = "<leader>/";
          action = ":noh<cr>";
          options.desc = "Clear search highlight";
        }
      ];

      plugins = {
        web-devicons.enable = true;
        leap.enable = true;
        sleuth.enable = true;
        nix.enable = true;
        colorizer.enable = true;
        fugitive.enable = true;
        gitignore.enable = false;
        direnv.enable = true;
        nvim-tree = {
          enable = true;
          settings = {
            on_attach.__raw = ''
              function(bufnr)
                local api = require('nvim-tree.api')

                local function opts(desc)
                  return { desc = 'nvim-tree: ' .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true }
                end
                api.config.mappings.default_on_attach(bufnr)

                vim.keymap.set('n', 't', api.node.open.tab, opts('Open in new tab'))
                vim.keymap.set('n', 's', api.node.open.horizontal, opts('Open in horizontal split'))
                vim.keymap.set('n', 'v', api.node.open.vertical, opts('Open in vertical split'))
              end
            '';
          };
        };
        none-ls = {
          enable = true;
          sources = {
            diagnostics.statix.enable = true;
            code_actions.statix.enable = true;
            diagnostics.deadnix.enable = true;
          };
        };

        oil = {
          enable = true;
          settings = {
            skip_confirm_for_simple_edits = true;
          };
        };

        conform-nvim = {
          enable = true;
          autoLoad = true;
          formatters = {
            squeeze_blanks.command = lib.getExe' pkgs.coreutils "cat";
            nixfmt.command = lib.getExe pkgs.nixfmt;
            ruff.command = lib.getExe pkgs.ruff;
          };
          settings = {
            formatters_by_ft = {
              "markdown" = [
                "squeeze_blanks"
                "trim_whitespace"
                "trim_newlines"
              ];
              nix = [
                "nixfmt"
              ];
              python = [
                "ruff_organize_imports"
                "ruff_format"
              ];
            };
            format_on_save =
              let
                timeout_ms = 1500;
                lsp_format = "fallback";
              in
              ''
                function(bufnr)
                  if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
                    return
                  end
                  return { timeout_ms = ${toString timeout_ms}, lsp_format = "${lsp_format}" }
                end
              '';
          };
        };

        vim-matchup = {
          enable = true;
          autoLoad = true;
          treesitter.enable = true;
        };

        rest = {
          enable = true;
          enableTelescope = true;
        };

        treesitter = {
          enable = true;
          highlight.enable = true;
          indent.enable = true;
          folding.enable = true;
        };

        telescope = {
          enable = true;
          keymaps = {
            "<leader>ff" = "find_files";
            "<leader>fg" = "live_grep";
            "<leader>fb" = "buffers";
          };
        };

        lsp = {
          enable = true;
          servers = {
            ts_ls.enable = true;
            svelte.enable = true;
            tailwindcss.enable = true;
            basedpyright.enable = true;
            nixd.enable = true;
            eslint.enable = true;
            bashls.enable = true;
            taplo.enable = true;
            jsonls.enable = true;
          };
          keymaps = {
            lspBuf = {
              K = "hover";
              gd = "definition";
              gD = "declaration";
              gr = "references";
              gi = "implementation";
              gt = "type_definition";
            };
            diagnostic = {
              "<leader>d" = "open_float";
              "<leader>j" = "goto_next";
              "<leader>k" = "goto_prev";
            };
          };
        };

        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            completion = {
              keyword_length = 2;
            };
            sources = [
              { name = "nvim_lsp"; }
              { name = "luasnip"; }
              { name = "path"; }
              { name = "buffer"; }
            ];
            mapping = {
              "<C-Space>" = "cmp.mapping.complete()";
              "<C-e>" = "cmp.mapping.close()";
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<S-Tab>" = "cmp.mapping(cmp.mapping.select_prev_item(), {'i', 's'})";
              "<Tab>" = "cmp.mapping(cmp.mapping.select_next_item(), {'i', 's'})";
            };
          };
        };
      };
    };
  };
}
