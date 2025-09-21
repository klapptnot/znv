do -- bootstrap
  local lazypath = vim.fs.joinpath (vim.fn.stdpath ("data"), "lazy", "lazy.nvim")
  --- @diagnostic disable-next-line: undefined-field
  if not vim.uv.fs_stat (lazypath) then
    vim.fn.system ({
      "git",
      "clone",
      "--filter=blob:none",
      "https://github.com/folke/lazy.nvim.git",
      "--branch=stable", -- latest stable release
      lazypath,
    })
  end

  vim.opt.rtp:prepend (lazypath)
end

-- Space is <leader> key
vim.g.mapleader = " "

ZNV = {
  less_complex_things = true,
  tweaks = {
    detect_indent = true,
    reset_cursor = true,
    lua_functions = true,
  },
  cache_path = vim.fs.joinpath (vim.fn.stdpath ("cache"), "znv"),
}

if not vim.uv.fs_stat (ZNV.cache_path) then vim.fn.mkdir (ZNV.cache_path, "p") end

require ("znv.tweaks").apply ()

--- @type ZnvConfig
local config = require ("config")

config.plugins:apply ()
config.options:apply ()
config
  .mapping
  :map ({ { "<C-z>", "<nop>" } }) -- disable backgrounding when <C-z> is pressed
  :apply ()

require ("znv.kalika").setup ({ transparent = true })

vim.api.nvim_cmd ({ cmd = "colorscheme", args = { "kalika" } }, {})

local toggles = require ("znv.toggle")

toggles.add (
  "diagnostic-lines",
  function (s) vim.diagnostic.config ({ virtual_lines = s }) end,
  true
)
toggles.add ("inlay-hints", function (s) vim.lsp.inlay_hint.enable (s) end, true)
toggles.add ("spell-check", function (s) vim.opt.spell = s end, false)
toggles.add ("mouse-support", function (s) vim.opt.mouse = s and "a" or "" end, true)

require ("znv.hotrel").setup ()
require ("znv.term").setup ()
require ("znv.palette.whichkey").setup ().map ("<leader>")
require ("znv.statusline").set ({
  ignore = "neo-tree,Outline,toggleterm",
  bar = {
    "mode",
    "file",
    "lsp_diag",
    "truncate",
    "shift_to_end",
    "git_stat",
    "cursor_pos",
    "file_encoding",
    "file_type",
    "file_eol",
  },
  colors = {
    mode = {
      normal = { bg = "#a6e3a1", fg = "#11111b" },
      insert = { bg = "#f5c2e7", fg = "#11111b" },
      visual = { bg = "#89dceb", fg = "#11111b" },
      prompt = { bg = "#eba0ac", fg = "#11111b" },
      replace = { bg = "#f38ba8", fg = "#11111b" },
      other = { bg = "#f9e2af", fg = "#11111b" },
    },
    cwd = { bg = "#2a2d3a", fg = "#cdd6f4" },
    file = {
      normal = { bg = "#1a1d2a", fg = "#cdd6f4" },
      modified = { bg = "#1a1d2a", fg = "#f9e2af" },
      readonly = { bg = "#1a1d2a", fg = "#f38ba8" },
      type = { bg = "#2a2d3a", fg = "#a6adc8" },
      eol = { bg = "#1a1d2a", fg = "#6c7086" },
      enc = { bg = "#1a1d2a", fg = "#9399b2" },
    },
    lsp = {
      name = { bg = "#1a1d2a", fg = "#cdd6f4" },
      error = { bg = "#1a1d2a", fg = "#f38ba8" },
      hint = { bg = "#1a1d2a", fg = "#89b4fa" },
      warn = { bg = "#1a1d2a", fg = "#fab387" },
      info = { bg = "#1a1d2a", fg = "#74c7ec" },
    },
    git = {
      branch = { bg = "#1a1d2a", fg = "#b4befe" },
      changed = { bg = "#1a1d2a", fg = "#f9e2af" },
      added = { bg = "#1a1d2a", fg = "#a6e3a1" },
      removed = { bg = "#1a1d2a", fg = "#f38ba8" },
    },
    cursor_pos = { bg = "#2a2d3a", fg = "#cdd6f4" },
    inactive = { bg = "#1e1e2e", fg = "#6c7086" },
  },
  separators = {
    r = "",
    l = "",
  },
}, true)
