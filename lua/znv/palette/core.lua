--- @alias PaletteWin {buf: integer, win: integer, max_h: integer, max_w: integer, cur_h: integer, cur_w: integer, row: integer}
--- @alias PaletteProps {display: PaletteWin, input: PaletteWin, state: any, width: integer, col: integer, open: boolean}

local function create_scratch_buf (opts)
  local buf = vim.api.nvim_create_buf (false, true)
  vim.api.nvim_clear_autocmds ({ buffer = buf })

  for opt, val in pairs (opts) do
    vim.api.nvim_set_option_value (opt, val, { buf = buf })
  end

  return buf
end

local main = {}

--- @param display PaletteWin
--- @param new_height integer
function main.resizeh (display, new_height)
  local cfg = vim.api.nvim_win_get_config (display.win)
  if cfg.height == new_height then return end

  new_height = math.min (display.max_h, new_height)

  -- Shift row if height is changing, to keep bottom anchored
  cfg.row = display.row + display.max_h - new_height
  if new_height == display.max_h then cfg.row = display.row end
  cfg.height = new_height
  display.cur_h = new_height

  vim.api.nvim_win_set_config (display.win, cfg)
end

-- Open display + input window
--- @param opts {title:string?, wh:integer?, ww:integer?}
--- @return function? close_fn, PaletteProps? props
function main.open (opts)
  opts = opts or {}
  local win_title = opts.title or " Select "
  local win_height = opts.wh
  local win_width = opts.ww
  local ui = vim.api.nvim_list_uis ()[1]
  if not ui then return end

  local state = {
    win = vim.api.nvim_get_current_win (),
    buf = vim.api.nvim_get_current_buf (),
    mod = vim.api.nvim_get_mode ().mode:lower ():sub (1, 1),
    pos = vim.api.nvim_win_get_cursor (0),
  }

  if win_height == nil then
    win_height = math.floor (ui.height / 2) - 5
  end
  if win_width == nil then
    win_width = math.floor (ui.width / 4)
  elseif ui.width < win_width - 2 then
    error("Window width is smaller than required")
  end
  local input_height = 1
  local total_height = win_height + input_height

  local row = ui.height - total_height - 5
  local col = 0

  -- === Display Window ===
  local display_buf = create_scratch_buf ({
    modifiable = false,
    swapfile = false,
    bufhidden = "wipe",
    buftype = "nofile",
  })

  local display_win = vim.api.nvim_open_win (display_buf, false, {
    relative = "editor",
    title = win_title,
    title_pos = "center",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  -- === Input Window ===
  local input_buf = create_scratch_buf ({
    swapfile = false,
    bufhidden = "wipe",
    buftype = "nofile",
    omnifunc = "",
    completefunc = "",
    tagfunc = "",
    formatexpr = "",
  })

  do
    local ok, cmp = pcall (require, "cmp.config")
    if ok then cmp.set_buffer ({ enabled = false }, input_buf) end
  end

  vim.api.nvim_command ("startinsert")

  local input_win = vim.api.nvim_open_win (input_buf, true, {
    relative = "editor",
    width = win_width,
    height = input_height,
    row = row + win_height + 5,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  local props = {
    display = {
      buf = display_buf,
      win = display_win,
      cur_h = win_height,
      cur_w = win_width,
      max_h = win_height,
      max_w = win_width,
      row = row,
    },
    input = {
      buf = input_buf,
      win = input_win,
      cur_h = input_height,
      cur_w = win_width,
      max_h = input_height,
      max_w = win_width,
      row = row + win_height + 5,
    },
    state = state,
    width = win_width,
    col = col,
    open = true,
  }

  local function close_palette ()
    vim.api.nvim_command ("stopinsert")
    vim.api.nvim_win_close (props.input.win, true)
    vim.api.nvim_win_close (props.display.win, true)
    vim.api.nvim_win_set_cursor (0, props.state.pos)
  end

  return close_palette, props
end

return main
