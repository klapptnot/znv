local api = require ("nvstp.api")

local function toggle_or_refs (toggle_fun, lay)
  return function ()
    local buf = vim.api.nvim_get_current_buf ()
    local buftype = vim.api.nvim_get_option_value ("buftype", { buf = buf })

    if buftype ~= "terminal" then
      toggle_fun ()
      return
    end

    -- Get the current terminal instance info
    local term_api = require ("nvstp.term")
    local current_instance = nil
    for _, instance in pairs (term_api.instances) do
      if instance.buf == buf then
        current_instance = instance
        break
      end
    end

    if current_instance and current_instance.lay == lay then
      toggle_fun ()
      return
    end

    api.find_and_open_refs ()
  end
end

--- @type vim.api.keyset.keymap
local _opts_lua = { expr = false, noremap = false }
--- @type vim.api.keyset.keymap
local _opts_map = { expr = false, silent = true }

--- @type NvstpKeyMap[]
return {
  -- ^ Lua functions
  {
    mapp = "<C-s>",
    mode = { "n", "v", "i" },
    exec = api.save,
    desc = "Save current file",
    opts = _opts_lua,
  },

  {
    mapp = "<C-q>",
    mode = { "n", "v", "i" },
    exec = api.quit,
    desc = "Quit nvim safely",
    opts = _opts_lua,
  },

  {
    mapp = "th",
    mode = { "n", "v" },
    exec = api.tab_prev,
    desc = "Go to prev tab/buffer",
    opts = _opts_lua,
  },

  {
    mapp = "tl",
    mode = { "n", "v" },
    exec = api.tab_next,
    desc = "Go to next tab/buffer",
    opts = _opts_lua,
  },

  {
    mapp = "tk",
    mode = { "n", "v" },
    exec = api.tab_new,
    desc = "Add a new tab/buffer",
    opts = _opts_lua,
  },

  {
    mapp = "tj",
    mode = { "n", "v" },
    exec = api.tab_close,
    desc = "Close tab/buffer",
    opts = _opts_lua,
  },

  {
    mapp = "tr",
    mode = { "n", "v" },
    exec = api.tab_rename,
    desc = "Rename current tab/buffer",
    opts = _opts_lua,
  },

  {
    mapp = "W",
    mode = { "n" },
    exec = api.win_jump,
    desc = "Easy jump to another window",
    opts = _opts_lua,
  },

  {
    mapp = "E",
    mode = { "n" },
    exec = api.win_close,
    desc = "Easy close picked window",
    opts = _opts_lua,
  },

  {
    mapp = "<leader>wR",
    mode = { "n" },
    exec = api.resize_win_interact,
    desc = "Interactively resize current window",
    opts = _opts_lua,
  },

  {
    mapp = "<leader>fr",
    mode = { "v", "n" },
    exec = api.find_and_open_refs,
    desc = "Open a path ref from buffer",
    opts = _opts_lua,
  },

  {
    mapp = "<A-Up>",
    mode = { "n", "i" },
    exec = api.move_line_up,
    desc = "Move line up",
    opts = _opts_lua,
  },

  {
    mapp = "<A-Down>",
    mode = { "n", "i" },
    exec = api.move_line_down,
    desc = "Move line down",
    opts = _opts_lua,
  },

  {
    mapp = "<C-Up>",
    mode = { "n" },
    exec = function () api.scroll_markdown_float (-4) end,
    desc = "Scroll up (?Hover/Main)",
    opts = _opts_lua,
  },

  {
    mapp = "<C-Down>",
    mode = { "n" },
    exec = function () api.scroll_markdown_float (4) end,
    desc = "Scroll down (?Hover/Main)",
    opts = _opts_lua,
  },

  {
    mapp = "<C-c>",
    mode = { "n", "v", "i" },
    exec = api.copy,
    desc = "Copy selected text/line",
    opts = _opts_lua,
  },

  {
    mapp = "<C-z>",
    mode = { "n", "v", "i" },
    exec = vim.cmd.undo,
    desc = "Undo",
    opts = _opts_lua,
  },

  {
    mapp = "<C-y>",
    mode = { "n", "v", "i" },
    exec = vim.cmd.redo,
    desc = "Redo",
    opts = _opts_lua,
  },

  {
    mapp = "<C-d>",
    mode = { "n", "i" },
    exec = api.duplicate_line,
    desc = "Duplicate selection",
    opts = _opts_lua,
  },

  {
    mapp = "<C-d>",
    mode = { "v" },
    exec = api.duplicate_selection,
    desc = "Duplicate selection",
    opts = _opts_lua,
  },

  {
    mapp = "<C-`>",
    mode = { "n", "v", "t" },
    exec = toggle_or_refs (api.toggle_fterm, "floating"),
    desc = "Toggle floating terminal",
    opts = _opts_lua,
  },

  {
    mapp = "<M-1>",
    mode = { "n", "v", "t" },
    exec = toggle_or_refs (api.toggle_hterm, "horizontal"),
    desc = "Toggle horizontal terminal",
    opts = _opts_lua,
  },

  {
    mapp = "<M-2>",
    mode = { "n", "v", "t" },
    exec = toggle_or_refs (api.toggle_vterm, "vertical"),
    desc = "Toggle vertical terminal",
    opts = _opts_lua,
  },

  {
    mapp = "<",
    mode = { "n", "v" },
    exec = api.remove_indent,
    desc = "Unindent",
    opts = _opts_lua,
  },

  {
    mapp = ">",
    mode = { "n", "v" },
    exec = api.add_indent,
    desc = "Indent",
    opts = _opts_lua,
  },

  {
    mapp = "<C-/>",
    mode = { "n", "v", "i" },
    exec = api.comment,
    desc = "Toggle comment",
    opts = _opts_lua,
  },

  {
    mapp = "<Home>",
    mode = { "n", "v", "i" },
    exec = api.home_key,
    desc = "Go to line home or line start",
    opts = _opts_lua,
  },

  {
    mapp = "<kHome>",
    mode = { "n", "v", "i" },
    exec = api.home_key,
    desc = "Go to line home or line start",
    opts = _opts_lua,
  },

  {
    mapp = "W",
    mode = { "v" },
    exec = api.wrap_selection,
    desc = "Wrap the visual selection",
    opts = _opts_lua,
  },

  {
    mapp = "<leader>sh",
    mode = { "n" },
    exec = "<Cmd>split<CR>",
    desc = "Split horizontally (below)",
    opts = _opts_map,
  },

  {
    mapp = "<leader>sv",
    mode = { "n" },
    exec = "<Cmd>vsplit<CR>",
    desc = "Split vertically (right)",
    opts = _opts_map,
  },

  {
    mapp = "<leader>wc",
    mode = { "n" },
    exec = "<Cmd>bwipeout<CR>",
    desc = "Close current buffer",
    opts = _opts_map,
  },

  {
    mapp = "<leader>wq",
    mode = { "n" },
    exec = "<Cmd>close<CR>",
    desc = "Close current window",
    opts = _opts_map,
  },

  {
    mapp = "<leader>wo",
    mode = { "n" },
    exec = "<Cmd>only<CR>",
    desc = "Close all other windows",
    opts = _opts_map,
  },

  {
    mapp = "<leader>wa",
    mode = { "n" },
    exec = "<Cmd>bufdo bwipeout<CR>",
    desc = "Close all buffers",
    opts = _opts_map,
  },

  {
    mapp = "<leader>wW",
    mode = { "n" },
    exec = "<Cmd>wa<CR>",
    desc = "Write all buffers",
    opts = _opts_map,
  },

  {
    mapp = "<leader>so",
    mode = { "n" },
    exec = "<Cmd>Outline<CR>",
    desc = "Toggle symbols tree",
    opts = _opts_map,
  },

  {
    mapp = "<leader><leader>",
    mode = { "n" },
    exec = "<Cmd>Telescope buffers<CR>",
    desc = "Telescope: Find buffers",
    opts = _opts_map,
  },

  {
    mapp = "<leader>fm",
    mode = { "n" },
    exec = "<Cmd>Telescope marks<CR>",
    desc = "Telescope: Find->Jump marks",
    opts = _opts_map,
  },

  {
    mapp = "<leader>ff",
    mode = { "n" },
    exec = "<Cmd>Telescope find_files<CR>",
    desc = "Telescope: Find files",
    opts = _opts_map,
  },

  {
    mapp = "<leader>fa",
    mode = { "n" },
    exec = "<Cmd>Telescope find_files follow=true hidden=true<CR>",
    desc = "Telescope: Find all",
    opts = _opts_map,
  },

  {
    mapp = "<leader>fw",
    mode = { "n" },
    exec = "<Cmd>Telescope live_grep<CR>",
    desc = "Telescope: Live grep",
    opts = _opts_map,
  },

  {
    mapp = "<leader>fh",
    mode = { "n" },
    exec = "<Cmd>Telescope help_tags<CR>",
    desc = "Telescope: Help pages",
    opts = _opts_map,
  },

  {
    mapp = "<leader>fo",
    mode = { "n" },
    exec = "<Cmd>Telescope oldfiles<CR>",
    desc = "Telescope: Find oldfiles",
    opts = _opts_map,
  },

  {
    mapp = "<leader>fz",
    mode = { "n" },
    exec = "<Cmd>Telescope current_buffer_fuzzy_find<CR>",
    desc = "Telescope: Find in current buffer (fuzzy)",
    opts = _opts_map,
  },

  {
    mapp = "<leader>gc",
    mode = { "n" },
    exec = "<Cmd>Telescope git_commits<CR>",
    desc = "Telescope: Git commits",
    opts = _opts_map,
  },

  {
    mapp = "<leader>gt",
    mode = { "n" },
    exec = "<Cmd>Telescope git_status<CR>",
    desc = "Telescope: Git status",
    opts = _opts_map,
  },

  {
    mapp = "<A-m>",
    mode = { "n", "i" },
    exec = "<Cmd>Man<CR>",
    desc = "Open man page for symbol under cursor",
    opts = _opts_map,
  },

  {
    mapp = "<leader>bn",
    mode = { "n" },
    exec = "<Cmd>bnext<CR>",
    desc = "Buffer: go to next",
    opts = _opts_map,
  },
  {
    mapp = "<leader>bp",
    mode = { "n" },
    exec = "<Cmd>bprevious<CR>",
    desc = "Buffer: go to previous",
    opts = _opts_map,
  },
  {
    mapp = "<leader>bd",
    mode = { "n" },
    exec = "<Cmd>bd<CR>",
    desc = "Buffer: delete current",
    opts = _opts_map,
  },

  -- do not save replaced selection
  {
    mapp = "p",
    mode = { "x" },
    exec = '"_dp',
    desc = "Paste",
    opts = _opts_map,
  },

  {
    mapp = "<C-BS>",
    mode = { "i" },
    exec = "<C-W>",
    desc = "Delete word backwards",
    opts = _opts_map,
  },
  -- Use gj|jk if no v:count
  -- https://www.reddit.com/r/vim/comments/2k4cbr/problem_with_gj_and_gk
  {
    mapp = "k",
    mode = { "v", "n" },
    exec = "(v:count == 0 ? 'gk' : 'k')",
    desc = "Move cursor up",
    opts = { silent = true, expr = true },
  },
  {
    mapp = "j",
    mode = { "v", "n" },
    exec = "(v:count == 0 ? 'gj' : 'j')",
    desc = "Move cursor down",
    opts = { silent = true, expr = true },
  },
  {
    mapp = "<Up>",
    mode = { "v", "n" },
    exec = "(v:count == 0 ? 'gk' : 'k')",
    desc = "Move cursor up",
    opts = { silent = true, expr = true },
  },
  {
    mapp = "<Down>",
    mode = { "v", "n" },
    exec = "(v:count == 0 ? 'gj' : 'j')",
    desc = "Move cursor down",
    opts = { silent = true, expr = true },
  },
  {
    mapp = "<C-I>",
    mode = { "v", "n" },
    exec = "0ggvG$",
    desc = "Select all",
    opts = { silent = true, expr = false },
  },

  {
    mapp = "b",
    mode = { "n", "v" },
    exec = api.add_toggle_hlmatch,
    desc = "Add/Toggle hlmatch",
    opts = { silent = true, expr = true },
  },
}
