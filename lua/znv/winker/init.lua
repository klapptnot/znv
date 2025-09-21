-- znv winker (window picker)

local fl = require ("znv.winker.font")
local utf8 = require ("warm.utf8")

local drawer = {
  font = "ansi-regular",
  chars = {
    "Q",
    "W",
    "E",
    "A",
    "S",
    "D",
    "Z",
    "X",
    "C",
    "R",
    "F",
    "1",
    "2",
    "3",
    "4",
  },
  lookup = {},
}

local function shrinkInteger (val)
  if val > 255 then return val - (val % 255) end
  if val < 0 then return 255 - (255 - val) end
  return val
end

-- Generates a color code per window at a (running) time
-- Same time and window gives same color, similar gives similar color
local function colorgen (i)
  local seed = os.clock () * i
  -- Use the seed to generate pseudo-random values for RGB components
  local r = math.floor ((seed * 16777215) % 256) -- 0 to 255
  local g = math.floor ((seed * 65535) % 256) -- 0 to 255
  local b = math.floor ((seed * 255) % 256) -- 0 to 255
  local l = (0.299 * r + 0.587 * g + 0.114 * b) / 255
  if l > 0.5 then
    r, g, b = shrinkInteger (r + 60), shrinkInteger (g + 60), shrinkInteger (b + 60)
  end

  -- Convert decimal values to hex strings with leading zeros
  -- and combine hex strings for the final color code
  return string.format ("#%02x%02x%02x", r, g, b)
end

--- @param wininfo {winid:number, color:string, char:string} Parent window handle
--- @return integer[]
function drawer:spawn_floating_hint (wininfo)
  local pwinid = wininfo.winid
  local color = wininfo.color
  local char = wininfo.char
  local font = self.fontd

  local bigchar = font:get_char (char).l
  local lines = {}

  local win = {
    h = font.height + 2,
    w = 0, -- Will be updated soon
  }

  if string.match (bigchar[font.height], "^%s*$") ~= nil then win.h = win.h - 1 end

  -- Calculate max width to match font width
  -- And create a string at index to allow concatenation
  for i = 1, win.h - 1 do
    win.w = math.max (win.w, utf8.len (bigchar[i]))
    lines[i + 1] = ""
  end
  win.w = win.w + 2

  -- Top and bottom lines are filled with space
  local fill = string.rep (" ", win.w)
  lines[1] = fill
  lines[#lines] = fill

  for i = 1, win.h - 2 do
    local bigchln = bigchar[i]
    -- if bigchln:sub(-1, -1) == " " then bigchln = bigchln:sub(1, -2) end
    local nw = win.w - utf8.len (bigchln)
    local fill_left = string.rep (" ", math.floor (nw / 2))
    local fill_right = string.rep (" ", math.ceil (nw / 2))
    lines[i + 1] = fill_left .. bigchln .. fill_right
  end
  lines = { table.concat (lines, "") .. " " }

  local pos = {
    x = ((vim.api.nvim_win_get_width (pwinid) - win.w) / 2),
    y = ((vim.api.nvim_win_get_height (pwinid) - win.h) / 2),
  }

  local buf_id = vim.api.nvim_create_buf (false, true)
  vim.api.nvim_buf_set_lines (buf_id, 0, 0, true, lines)
  local window_id = vim.api.nvim_open_win (buf_id, false, {
    relative = "win",
    win = pwinid,
    focusable = false,
    row = pos.y,
    col = pos.x,
    width = win.w,
    height = win.h,
    noautocmd = true,
    style = "minimal",
  })

  local hi = "WinckerFG_" .. color:sub (2)
  local mi = 0
  -- Add color to each window
  vim.api.nvim_win_call (window_id, function ()
    vim.api.nvim_set_hl (0, hi, { fg = color })
    mi = vim.fn.matchadd (hi, [[.*]])
  end)
  return { window_id, mi }
end

--- @param windows {winid:number, color:string, char:string}[]
function drawer:draw (windows)
  self.fontd = fl.load (self.font)
  self.markers = {}
  for _, win in ipairs (windows) do
    table.insert (self.markers, self:spawn_floating_hint (win))
  end
end

function drawer:clear ()
  for _, v in ipairs (self.markers) do
    local win = v[1]
    if vim.api.nvim_win_is_valid (win) then
      local buffer = vim.api.nvim_win_get_buf (win)
      vim.fn.matchdelete (v[2], win)
      vim.api.nvim_win_close (win, true)
      vim.api.nvim_buf_delete (buffer, { force = true })
    end
  end
  -- Remove foreground color match group
  self.markers = {}
end

local main = {}

--- Pick a window and return information about its selection
--- @return {char:integer, data:{winid:integer, color:string, char:string}}?
function main.select ()
  local win_list = {}
  local lookup = {}

  for nr, win in ipairs (vim.api.nvim_list_wins ()) do
    -- local nr = vim.fn.win_id2win(win)
    lookup[drawer.chars[nr]] = nr
    win_list[nr] = {
      winid = win,
      color = colorgen (win),
      char = drawer.chars[nr],
      -- char = string.char(nr + 64),
    }
  end

  drawer:draw (win_list)
  vim.api.nvim_command ("redraw")

  local ok, ch = pcall (vim.fn.getchar)
  drawer:clear ()
  vim.api.nvim_command ("redraw")
  if not ok or type (ch) ~= "number" then return end -- Any <key>

  if ch < 21 or ch > 126 then return end -- Invalid character range
  if ch > 96 and ch < 123 then ch = ch - 32 end -- Uppercase it

  local ich = lookup[vim.fn.nr2char (ch)]
  if win_list[ich] == nil then return { char = ch, data = nil } end

  return {
    char = ch,
    data = win_list[ich],
  }
end

--- Pick a window and jump into it
function main.jump ()
  local res = main.select ()
  if res == nil then
    vim.notify ("Could not get selected window", vim.log.levels.ERROR, { title = "Winker" })
    return
  end
  if res.data == nil then
    if res.char == 27 then return end -- <Esc>
    vim.notify (
      "Window with mark: '" .. vim.fn.nr2char (res.char) .. "' does not exist",
      vim.log.levels.ERROR,
      { title = "Winker" }
    )
    return
  end
  if not vim.api.nvim_win_is_valid (res.data.winid) then
    vim.notify (
      "Window with mark: '" .. vim.fn.nr2char (res.char) .. "' is not a valid window",
      vim.log.levels.ERROR,
      { title = "Winker" }
    )
    return
  end
  vim.api.nvim_set_current_win (res.data.winid)
end

return main
