{
  config,
  inputs,
  lib,
  lib',
  pkgs,
  ...
}:

let
  colors = lib'.semantic-colors;
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

      diagnostic.settings = {
        underline = false;
        virtual_text = false;
        signs = true;
      };

      highlight = with colors; {
        # Treesitter
        "@variable" = {
          fg = violet-50;
        };

        "@variable.parameter" = {
          fg = red-200;
        };

        "@variable.builtin" = {
          fg = rose-300;
        };

        "@property" = {
          fg = teal-100;
        };

        Normal = {
          fg = amber-100;
          bg = ocean-800;
        };
        NormalFloat = {
          fg = amber-50;
          bg = ocean-800;
        };
        NormalNC = {
          fg = stone-400;
          bg = ocean-900;
        };

        Comment = {
          fg = neutral-500;
          italic = true;
        };
        String = {
          fg = lime-200;
        };
        Number = {
          fg = cyan-200;
        };
        Constant = {
          fg = emerald-200;
        };
        Identifier = {
          fg = stone-500;
        };
        Function = {
          fg = slate-400;
        };
        Keyword = {
          fg = rose-400;
        };
        Operator = {
          fg = stone-500;
        };
        PreProc = {
          fg = slate-400;
        };
        Type = {
          fg = zinc-400;
        };
        Special = {
          fg = orange-300;
        };
        Delimiter = {
          fg = red-400;
        };

        DiagnosticError = {
          fg = rose-400;
        };
        DiagnosticWarn = {
          fg = orange-300;
        };
        DiagnosticHint = {
          fg = emerald-200;
        };
        DiagnosticInfo = {
          fg = indigo-300;
        };

        DiffAdd = {
          bg = green-800;
        };
        DiffDelete = {
          bg = rose-400;
        };
        DiffChange = {
          bg = slate-800;
        };
        DiffText = {
          bg = stone-500;
        };
        Added = {
          fg = green-200;
        };
        Removed = {
          fg = red-600;
        };
        Changed = {
          fg = orange-300;
        };

        Visual = {
          bg = rose-500;
        };
        Search = {
          bg = slate-500;
        };
        NonText = {
          fg = stone-400;
        };
        Whitespace = {
          fg = stone-400;
        };
        LineNr = {
          fg = neutral-500;
          bg = ocean-900;
        };
        CursorLineNr = {
          fg = orange-300;
          bg = ocean-900;
        };
        SignColumn = {
          bg = ocean-900;
        };
        Pmenu = {
          fg = stone-400;
          bg = zinc-700;
        };
        PmenuSel = {
          bg = zinc-800;
        };
        PmenuSbar = {
          bg = slate-700;
        };
        PmenuThumb = {
          bg = slate-500;
        };
      };

      globals.mapleader = "\\";

      opts = {
        number = true;
        shiftwidth = 2;
        cursorline = true;
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
        typst-vim.enable = true;
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
            formatters = {
              typstyle.command = lib.getExe pkgs.typstyle;
            };
            formatters_by_ft = {
              markdown = [
                "squeeze_blanks"
                "trim_whitespace"
                "trim_newlines"
              ];
              typst = [
                "typstyle"
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
            tinymist.enable = true;
            ts_ls.enable = true;
            svelte.enable = true;
            tailwindcss.enable = true;
            basedpyright.enable = true;
            ty.enable = false; # swap with basedpyright mid 2027
            ruff.enable = true;
            nixd.enable = true;
            eslint.enable = true;
            bashls.enable = true;
            tombi.enable = true;
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
