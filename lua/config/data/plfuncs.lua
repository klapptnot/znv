local main = {}

function main.lspconfig ()
  local lspconfig = require ("lspconfig")
  local fns_on_attach = function (client, bufnr)
    local mapps = require ("config.data.lspmapps")

    for _, prop in ipairs (mapps) do
      if client:supports_method (prop.meth) then
        prop.opts.desc = prop.desc -- Just to not nest items
        prop.opts.callback = prop.exec

        for _, mode in ipairs (prop.mode) do
          vim.api.nvim_buf_set_keymap (bufnr, mode, prop.mapp, "", prop.opts)
        end
      end
    end
  end

  local fns_capabilities =
    vim.lsp.protocol.resolve_capabilities (vim.lsp.protocol.make_client_capabilities ())

  local shared_opts = {
    hints = {
      enable = true,
    },
    on_attach = fns_on_attach,
    capabilities = fns_capabilities,
  }

  lspconfig.rust_analyzer.setup (shared_opts)
  lspconfig.zls.setup (shared_opts)
  lspconfig.clangd.setup (shared_opts)
  lspconfig.pyright.setup (shared_opts)
  lspconfig.nushell.setup (shared_opts)
  lspconfig.ts_ls.setup (shared_opts)
  lspconfig.bashls.setup (shared_opts)
  lspconfig.html.setup (shared_opts)
  lspconfig.lua_ls.setup ({
    on_attach = fns_on_attach,
    capabilities = fns_capabilities,
    settings = {
      Lua = {
        hints = {
          enable = true,
        },
        diagnostics = {
          globals = { "vim" },
        },
        workspace = {
          library = {
            [vim.fn.expand ("$VIMRUNTIME/lua")] = true,
            [vim.fn.expand ("$VIMRUNTIME/lua/vim/lsp")] = true,
            [vim.fn.stdpath ("data") .. "/lazy/lazy.nvim/lua/lazy"] = true,
          },
          maxPreload = 100000,
          preloadFileSize = 10000,
        },
      },
    },
  })
  -- lspconfig.jsonls.setup({
  --   hints = {
  --     enable = true,
  --   },
  --   on_attach = fns_on_attach,
  --   capabilities = fns_capabilities,
  --   settings = {
  --     schemas = require("config.data.jsonsch"),
  --   },
  -- })
end

function main.tabby ()
  -- stylua: ignore
  local theme = {
    fill    = { fg = "#202020" },
    head    = { fg = "#202020", bg = "#ffe8b8", style = "italic" },
    cur_tab = { fg = "#202020", bg = "#ffa98c", style = "bold" },
    cur_win = { fg = "#202020", bg = "#e188a4", style = "bold" },
    tab     = { fg = "#202020", bg = "#a198b4", style = "italic" },
    win     = { fg = "#202020", bg = "#a198b4", style = "italic" },
    tail    = { fg = "#202020", bg = "#ffe8b8", style = "italic" },
  }
  require ("tabby.tabline").set (function (line)
    return {
      {
        { "  " .. vim.fs.basename (vim.fn.getcwd ()) .. " ", hl = theme.head },
        line.sep ("", theme.head, theme.fill),
      },
      line.tabs ().foreach (function (tab)
        local hl = tab.is_current () and theme.cur_tab or theme.tab
        return {
          line.sep (" ", hl, theme.fill),
          tab.is_current () and "" or "󰆣",
          tab.number (),
          tab.name (),
          tab.close_btn (""),
          line.sep ("", hl, theme.fill),
          hl = hl,
          margin = " ",
        }
      end),
      line.spacer (),
      -- line.wins_in_tab (line.api.get_current_tab ()).foreach (function (win)
      --   local hl = win.is_current () and theme.cur_win or theme.win
      --   return {
      --     line.sep (" ", hl, theme.fill),
      --     win.is_current () and "" or "",
      --     win.buf_name (),
      --     line.sep ("", hl, theme.fill),
      --     hl = hl,
      --     margin = " ",
      --   }
      -- end),
      {
        line.sep (" ", theme.tail, theme.fill),
        { "  ", hl = theme.tail },
      },
      hl = theme.fill,
    }
  end)
end

function main.autopairs ()
  local nvim_autopairs = require ("nvim-autopairs")
  local nvim_autopairs_cmp = require ("nvim-autopairs.completion.cmp")
  --- @diagnostic disable-next-line: different-requires
  local cmp = require ("cmp")

  nvim_autopairs.setup ({
    disable_filetype = { "TelescopePrompt", "spectre_panel" },
    disable_in_macro = true, -- disable when recording or executing a macro
    disable_in_visualblock = false, -- disable when insert after visual block mode
    disable_in_replace_mode = true,
    ignored_next_char = [=[[%w%%%'%[%"%.%`%$]]=],
    enable_moveright = true,
    enable_afterquote = true, -- add bracket pairs after quote
    enable_check_bracket_line = true, --- check bracket in same line
    enable_bracket_in_quote = true,
    enable_abbr = false, -- trigger abbreviation
    break_undo = true, -- switch for basic rule break undo sequence
    map_bs = true, -- map the <BS> key
    map_c_h = false, -- Map the <C-h> key to delete a pair
    map_c_w = false, -- map <c-w> to delete a pair if possible
    check_ts = true,
    map_cr = true, --  map <CR> on insert mode
    map_complete = true, -- it will auto insert `(` (map_char) after select function or method item
    auto_select = false, -- auto select first item
    map_char = {
      -- modifies the function or method delimiter by filetypes
      all = "(",
      tex = "{",
    },
  })

  -- If you want insert `(` after select function or method item
  --- @diagnostic disable-next-line: undefined-field
  cmp.event:on ("confirm_done", nvim_autopairs_cmp.on_confirm_done ())
end

function main.luasnip ()
  require ("luasnip").config.set_config ({
    history = true,
    updateevents = "TextChanged,TextChangedI",
  })
  require ("luasnip.loaders.from_vscode").lazy_load ()
  require ("luasnip.loaders.from_vscode").lazy_load ({
    paths = vim.g.vscode_snippets_path or "",
  })
  require ("luasnip.loaders.from_snipmate").load ()
  require ("luasnip.loaders.from_snipmate").lazy_load ({
    paths = vim.g.snipmate_snippets_path or "",
  })
  require ("luasnip.loaders.from_lua").load ()
  require ("luasnip.loaders.from_lua").lazy_load ({ paths = vim.g.lua_snippets_path or "" })
  vim.api.nvim_create_autocmd ("InsertLeave", {
    callback = function ()
      if
        require ("luasnip").session.current_nodes[vim.api.nvim_get_current_buf ()]
        and not require ("luasnip").session.jump_active
      then
        require ("luasnip").unlink_current ()
      end
    end,
  })
end

function main.cmp ()
  -- stylua: ignore
  local kind_icons = {
    Text          = " ",
    Method        = "󰆧 ",
    Function      = "󰊕 ",
    Constructor   = " ",
    Field         = "󰇽 ",
    Variable      = "󰂡 ",
    Class         = "󰠱 ",
    Interface     = " ",
    Module        = " ",
    Property      = "󰜢 ",
    Unit          = " ",
    Value         = "󰎠 ",
    Enum          = " ",
    Keyword       = "󰌋 ",
    Snippet       = " ",
    Color         = "󰏘 ",
    File          = "󰈙 ",
    Reference     = " ",
    Folder        = "󰉋 ",
    EnumMember    = " ",
    Constant      = "󰏿 ",
    Struct        = " ",
    Event         = " ",
    Operator      = "󰆕 ",
    TypeParameter = "󰅲 ",
  }

  local borders = {
    { "╭", "CMPBorder" },
    { "─", "CMPBorder" },
    { "╮", "CMPBorder" },
    { "│", "CMPBorder" },
    { "╯", "CMPBorder" },
    { "─", "CMPBorder" },
    { "╰", "CMPBorder" },
    { "│", "CMPBorder" },
  }
  local cmp = require ("cmp")
  local luasnip = require ("luasnip")
  cmp.setup ({
    window = {
      completion = {
        side_padding = 0, -- flat_dark
        border = borders,
      },
      documentation = {
        border = borders,
      },
    },
    snippet = {
      expand = function (args) luasnip.lsp_expand (args.body) end,
    },
    experimental = {
      native_menu = false,
      ghost_text = true,
    },
    formatting = {
      fields = { "abbr", "kind", "menu" },
      format = function (entry, vim_item)
        -- load lspkind icons
        vim_item.kind = kind_icons[vim_item.kind] .. " " .. vim_item.kind

        --       |
        -- stylua: ignore
        vim_item.menu = ({
          nvim_lsp = "󰒌 ",
          nvim_lua = " ",
          luasnip  = " ",
          buffer   = " ",
          path     = " ",
          calc     = "󰃬 ",
          cmdline  = " ",
        })[entry.source.name] or " "

        return vim_item
      end,
    },
    mapping = {
      ["<C-Up>"] = cmp.mapping.scroll_docs (-8),
      ["<C-Down>"] = cmp.mapping.scroll_docs (8),
      ["<C-o>"] = cmp.mapping.open_docs (),
      ["<Cr>"] = cmp.mapping.confirm ({ select = false }),
      ["<Esc>"] = cmp.mapping.close (),
      ["<Up>"] = cmp.mapping.select_prev_item ({ behavior = "select" }),
      ["<Down>"] = cmp.mapping.select_next_item ({ behavior = "select" }),
      ["<Tab>"] = cmp.mapping (function (fallback)
        if luasnip.locally_jumpable (1) then
          luasnip.jump (1)
        else
          fallback ()
        end
      end, { "s" }),

      ["<S-Tab>"] = cmp.mapping (function (fallback)
        if luasnip.locally_jumpable (-1) then
          luasnip.jump (-1)
        else
          fallback ()
        end
      end, { "s" }),
    },
    sources = {
      { name = "nvim_lua" },
      { name = "nvim_lsp" },
      { name = "treesitter" },
      { name = "luasnip" },
      { name = "emoji" },
      { name = "path" },
      { name = "calc" },
      {
        name = "buffer",
        keyword_length = 5,
        option = {
          get_bufnr = function () return vim.api.nvim_list_bufs () end,
        },
      },
      { name = "crates" }, -- crates does check if file is a `Cargo.toml` file
    },
  })
  cmp.setup.cmdline (":", {
    mapping = cmp.mapping.preset.cmdline (),
    sources = cmp.config.sources ({
      { name = "path" },
      {
        name = "cmdline",
        option = {},
      },
    }),
  })
  cmp.setup.cmdline ({ "/", "?" }, {
    mapping = cmp.mapping.preset.cmdline (),
    sources = {
      { name = "buffer" },
    },
  })
end

function main.null_ls ()
  local null_ls = require ("null-ls")
  -- local helpers = require("null-ls.helpers")

  null_ls.setup ({
    sources = {
      -- Formatting
      null_ls.builtins.formatting.black,
      null_ls.builtins.formatting.shfmt.with ({
        args = {
          "-filename",
          "$FILENAME",
          "-i",
          "2",
          "-ci",
          "-bn",
          "-sr",
          "-",
        },
      }),
    },
  })

  vim.api.nvim_create_autocmd ("LspAttach", {
    desc = "LSP actions",
    callback = function (ev)
      local client = vim.lsp.get_client_by_id (ev.data.client_id)
      local bufnr = ev.buf

      if not client or client.name ~= "null-ls" then
        return
      end

      -- If we reach here, the client is null-ls, so proceed with the keymapping
      vim.defer_fn (function ()
        for _, mode in ipairs ({ "n", "v" }) do
          pcall (vim.api.nvim_buf_del_keymap, bufnr, mode, "<leader>lf")
          vim.api.nvim_buf_set_keymap (bufnr, mode, "<leader>lf", "", {
            desc = "[NLS] Format document or selection",
            callback = function ()
              vim.lsp.buf.format ({ async = true, name = "null-ls" })
            end,
            silent = true,
          })
        end
      end, 500)
    end,
  })
end

function main.treesitter ()
  local configs = require ("nvim-treesitter.configs")
  configs.setup ({
    ensure_installed = {
      "c",
      "lua",
      "vim",
      "vimdoc",
      "rust",
      "python",
      "bash",
      "javascript",
      "fish",
      "json5",
      "yaml",
      "java",
    },
    sync_install = true,
    auto_install = true,
    highlight = { enable = true },
    indent = { enable = true },
  })
end

function main.init_gitsigns ()
  -- load gitsigns only when a git file is opened
  vim.api.nvim_create_autocmd ({ "BufRead" }, {
    group = vim.api.nvim_create_augroup ("GitSignsLazyLoad", { clear = true }),
    callback = function ()
      vim.fn.jobstart ({
        "git",
        "-C",
        --- @diagnostic disable-next-line: undefined-field
        vim.uv.cwd (),
        "rev-parse",
      }, {
        on_exit = function (_, return_code)
          if return_code == 0 then
            vim.api.nvim_del_augroup_by_name ("GitSignsLazyLoad")
            vim.schedule (
              function ()
                require ("lazy").load ({
                  plugins = {
                    "gitsigns.nvim",
                  },
                })
              end
            )
          end
        end,
      })
    end,
  })
end

return main
