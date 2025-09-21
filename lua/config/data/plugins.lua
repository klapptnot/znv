local funcs = require ("config.data.plfuncs")

return {
  { "nvim-tree/nvim-web-devicons", lazy = true },

  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    opts = {},
  },

  {
    "RRethy/vim-illuminate",
    event = { "BufReadPre", "BufNewFile" },
  },

  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
  },

  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter",
    dependencies = {
      {
        "L3MON4D3/LuaSnip",
        dependencies = "rafamadriz/friendly-snippets",
        config = funcs.luasnip,
      },
      {
        "hrsh7th/cmp-nvim-lua",
        "hrsh7th/cmp-nvim-lsp",
        "hrsh7th/cmp-cmdline",
        "hrsh7th/cmp-buffer",
        "hrsh7th/cmp-emoji",
        "hrsh7th/cmp-path",
        "hrsh7th/cmp-calc",
        "saadparwaiz1/cmp_luasnip",
        "rafamadriz/friendly-snippets",
      },
    },
    config = funcs.cmp,
  },

  {
    "j-hui/fidget.nvim",
    tag = "v1.6.1", -- Make sure to update this to something recent!
    event = { "LspAttach" },
    opts = {
      progress = {
        display = {
          render_limit = 16, -- How many LSP messages to show at once
          done_ttl = 2, -- How long a message should persist after completion
          done_icon = "✔", -- Icon shown when all LSP progress tasks are complete
          done_style = "Constant", -- Highlight group for completed LSP tasks
          progress_ttl = math.huge, -- How long a message should persist when in progress
          -- Icon shown when LSP progress tasks are in progress
          progress_icon = { "dots" },
          -- Highlight group for in-progress LSP tasks
          progress_style = "WarningMsg",
          group_style = "Title", -- Highlight group for group name (LSP server name)
          icon_style = "Question", -- Highlight group for group icons
          priority = 30, -- Ordering priority for LSP notification group
          skip_history = true, -- Whether progress notifications should be omitted from history
          -- How to format a progress message
          -- format_message = require("fidget.progress.display").default_format_message,
          -- How to format a progress annotation
          format_annote = function (msg) return msg.title end,
          -- How to format a progress notification group's name
          format_group_name = function (group) return tostring (group) end,
          overrides = { -- Override options from the default notification config
            rust_analyzer = { name = "rust-analyzer" },
            lua_ls = { name = "lua-ls" },
          },
        },
      },
      notification = {
        -- Options related to the notification window and buffer
        window = {
          normal_hl = "Comment", -- Base highlight group in the notification window
          winblend = 0, -- Background color opacity in the notification window
          border = "none", -- Border around the notification window
          zindex = 45, -- Stacking priority of the notification window
          max_width = 0, -- Maximum width of the notification window
          max_height = 0, -- Maximum height of the notification window
          x_padding = 1, -- Padding from right edge of window boundary
          y_padding = 0, -- Padding from bottom edge of window boundary
          align = "bottom", -- How to align the notification window
          relative = "editor", -- What the notification window position is relative to
        },
      },
    },
  },

  {
    "folke/trouble.nvim",
    opts = {
      auto_close = false, -- auto close when there are no items
      auto_open = false, -- auto open when there are items
      auto_preview = false, -- automatically open preview when on an item
      auto_refresh = true, -- auto refresh when open
      auto_jump = false, -- auto jump to the item when there's only one
    }, -- for default options, refer to the configuration section for custom setup.
    cmd = "Trouble",
    keys = {
      {
        "<leader>xx",
        "<cmd>Trouble diagnostics toggle<cr>",
        desc = "[Trouble] Diagnostics",
      },
      {
        "<leader>xX",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "[Trouble] Buffer Diagnostics",
      },
      {
        "<leader>cs",
        "<cmd>Trouble symbols toggle focus=false<cr>",
        desc = "[Trouble] Symbols",
      },
      {
        "<leader>cl",
        "<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
        desc = "[Trouble] LSP Definitions",
      },
      {
        "<leader>xL",
        "<cmd>Trouble loclist toggle<cr>",
        desc = "[Trouble] Location List",
      },
      {
        "<leader>xQ",
        "<cmd>Trouble qflist toggle<cr>",
        desc = "[Trouble] Quickfix List",
      },
    },
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = funcs.autopairs,
  },

  {
    "nanozuki/tabby.nvim",
    event = "VimEnter",
    config = funcs.tabby,
  },

  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = funcs.treesitter,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile", "BufEnter", "BufWinEnter" },
    opts = {
      current_line_blame = true,
    },
    init = funcs.init_gitsigns,
  },

  {
    "hedyhli/outline.nvim",
    event = { "LspAttach" },
    lazy = true,
    cmd = { "Outline" },
    opts = {
      guides = {
        enabled = true,
      },
      keymaps = {
        close = { "<Esc>", "q" },
        code_actions = "a",
        fold = "f",
        fold_all = "F",
        fold_reset = "R",
        goto_location = "<CR>",
        hover_symbol = "<C-Space>",
        peek_location = "o",
        rename_symbol = "r",
        toggle_preview = "p",
        unfold = "u",
        unfold_all = "U",
      },
      outline_items = {
        highlight_hovered_item = true,
        show_symbol_details = true,
      },
      outline_window = {
        auto_close = false,
        position = "right",
        relative_width = true,
        show_numbers = true,
        show_relative_numbers = true,
        width = 25,
        wrap = true,
      },
      preview_window = {
        auto_preview = false,
        winhl = "Normal:Pmenu",
      },
      symbol_folding = {
        auto_unfold_hover = true,
        markers = { "", "" },
      },
    },
  },

  {
    "shellRaining/hlchunk.nvim",
    event = { "UIEnter", "BufReadPre", "BufNewFile" },
    opts = {
      exclude_filetypes = {
        terminal = true,
      },
      priority = {
        "chunk",
        "indent",
        "blank",
        "line_num",
      },
      -- items
      indent = {
        chars = { "", "", "|" },
        style = {
          "#b0bfff",
          "#f0bfff",
        },
        enable = true,
      },
      chunk = {
        use_treesitter = true,
        style = {
          "#f0bfff",
          "#f38ba8",
        },
        chars = {
          horizontal_line = "─",
          vertical_line = "│",
          left_top = "╭",
          left_bottom = "╰",
          right_arrow = "➜",
        },
        enable = true,
        duration = 0,
        delay = 0,
      },
      -- blank = {
      --   chars = { "." },
      --   style = {
      --     "#606090",
      --   },
      --   enable = false,
      -- },
      -- line_num = {
      --   enable = false,
      -- },
    },
  },

  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile", "BufWinEnter" },
    name = "null-ls",
    config = funcs.null_ls,
  },

  {
    "williamboman/mason.nvim",
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },

  {
    "williamboman/mason-lspconfig.nvim",
    event = { "BufReadPre", "BufNewFile", "BufWinEnter" },
    opts = {
      ensure_installed = {
        "lua_ls",
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPre", "BufNewFile", "BufWinEnter" },
    opts = {
      inlay_hints = { enabled = true },
    },
    config = funcs.lspconfig,
  },

  {
    "NvChad/nvim-colorizer.lua",
    init = function () require ("colorizer").setup () end,
  },
  {
    "rcarriga/nvim-notify",
    name = "notify",
    init = function ()
      if ZNV.less_complex_things == false then
        -- Just to ignore notification
        require ("notify").setup ({ background_colour = "#000000" })
        vim.notify = require ("notify")
      end
    end,
  },

  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = function ()
      require ("catppuccin").setup ({
        transparent_background = true,
        integrations = {
          fidget = true,
          gitsigns = true,
          markdown = true,
          lsp_trouble = true,
          symbols_outline = true,
          mason = true,
          cmp = true,
          illuminate = {
            enabled = true,
            lsp = true,
          },
          native_lsp = {
            enabled = true,
            virtual_text = {
              errors = { "italic" },
              hints = { "italic" },
              warnings = { "italic" },
              information = { "italic" },
              ok = { "italic" },
            },
            underlines = {
              errors = { "underline" },
              hints = { "underline" },
              warnings = { "underline" },
              information = { "underline" },
              ok = { "underline" },
            },
            inlay_hints = {
              background = true,
            },
          },
        },
      })
    end,
  },
}
