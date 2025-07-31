local main = {}
local str = require ("warm.str")
local match = require ("warm.spr").match

--- Returns whether the current mode is visual mode or not
--- @return boolean
function main.is_visual_mode ()
  local mode = vim.api.nvim_get_mode ().mode:sub (1, 1)
  return (mode == "v" or mode == "V" or mode == "")
end

--- @param buf? integer
--- @return boolean
function main.is_buf_modifiable (buf)
  return vim.api.nvim_get_option_value ("modifiable", { buf = buf or 0 })
end

--- @param buf? integer
--- @return boolean
function main.is_buf_modified (buf)
  return vim.api.nvim_get_option_value ("modified", { buf = buf or 0 })
end

--- @param buf? integer
--- @return boolean
function main.is_buf_named (buf) return vim.api.nvim_buf_get_name (buf or 0) ~= "" end

--- @param buf? integer
--- @return boolean
function main.is_buf_empty (buf)
  local lns = vim.api.nvim_buf_get_lines (buf or 0, 0, -1, false)
  return lns[1] == "" and #lns == 1
end

--- Send ESC key press, usually to go back to normal mode
function main.press_esc_key ()
  vim.api.nvim_feedkeys (vim.api.nvim_replace_termcodes ("<Esc>", true, false, true), "m", true)
end

--- Move cursor like VS Code does when Home key is pressed
function main.home_key ()
  local line_nr, cursor_pos = table.unpack (vim.api.nvim_win_get_cursor (0))
  local line = vim.api.nvim_buf_get_lines (0, line_nr - 1, line_nr, false)[1]

  local content_pos = (string.find (line, "%S") or 1) - 1
  -- Check if cursor is at the beginning of the line content
  if cursor_pos == content_pos then
    vim.api.nvim_win_set_cursor (0, { line_nr, 0 })
  else
    -- Move cursor to the start of the line content
    vim.api.nvim_win_set_cursor (0, { line_nr, content_pos })
  end
end

-- Return if buffer is modifiable and notify user if not
function main.is_buf_modifiable_notify ()
  if not main.is_buf_modifiable () then
    vim.notify ("Buffer is not modifiable", vim.log.levels.ERROR, {})
    return false
  end
  return true
end

--- Check if path exists and it represents a `kind`
--- @param path string
--- @param kind "file"|"directory"
--- @return boolean
function main.path_exists_and_is (path, kind)
  --- @diagnostic disable-next-line: undefined-field
  local path_info = vim.uv.fs_stat (path)
  return path_info ~= nil and path_info.type == kind
end

--- Check for possible refs in current buffer, and open selected one
--- @param deep? boolean Whether to check all colon-followed strings
function main.find_and_open_refs (deep)
  local pattern = "([%w%p]+%.%w+):?(%d*):?(%d*)"
  if deep == true then pattern = "([%w%p]+):(%d*):?(%d*)" end
  local api = vim.api
  local fn = vim.fn

  local current_buf = api.nvim_get_current_buf ()

  local lines = api.nvim_buf_get_lines (current_buf, 0, -1, false)
  local content = table.concat (lines, "\n")

  local paths = {}
  for path, row, col in content:gmatch (pattern) do
    table.insert (paths, {
      path = path,
      row = row ~= "" and tonumber (row) or 1,
      col = col ~= "" and tonumber (col) or 1,
    })
  end

  if #paths == 0 then
    vim.notify ("No file paths found in current buffer", vim.log.levels.INFO, {})
    return
  end

  local base_dir = fn.getcwd ()

  local valid_paths = {}
  for _, path_info in ipairs (paths) do
    local path = path_info.path
    local full_path = path

    if not path:match ("^/") then full_path = vim.fs.joinpath (base_dir, path) end

    if main.path_exists_and_is (full_path, "file") then
      table.insert (valid_paths, {
        path = vim.fs.normalize (full_path),
        row = path_info.row,
        col = path_info.col,
      })
    end
  end

  if #valid_paths == 0 then
    vim.notify ("No valid file paths found", vim.log.levels.INFO, {})
    return
  end

  local path_options = {}
  for _, path_info in ipairs (valid_paths) do
    local display = path_info.path
    if path_info.row then
      display = display .. ":" .. path_info.row
      if path_info.col then display = display .. ":" .. path_info.col end
    end
    table.insert (path_options, display)
  end

  vim.ui.select (path_options, {
    prompt = "Select a file to open:",
    format_item = function (item) return item end,
  }, function (selected)
    if not selected then return end

    local selected_idx = 0
    for i, option in ipairs (path_options) do
      if option == selected then
        selected_idx = i
        break
      end
    end

    if selected_idx > 0 then
      local path_info = valid_paths[selected_idx]

      local win = api.nvim_get_current_win ()
      local buf = api.nvim_get_current_buf ()

      if api.nvim_get_option_value ("filetype", { buf = buf }) == "terminal" then
        api.nvim_win_close (win, true)
        win = api.nvim_get_current_win ()
      end

      local windows = api.nvim_list_wins ()
      if #windows > 1 then
        local selected_win = require ("nvstp.winker.init").select ()
        if selected_win and api.nvim_win_is_valid (selected_win.data.winid) then
          win = selected_win.data.winid
        else
          if selected_win == nil then
            vim.notify ("No window selected", vim.log.levels.INFO)
            return
          else
            vim.notify ("Selected window is not valid", vim.log.levels.ERROR, {})
            return
          end
        end
      end

      local ref_buf = fn.bufadd (path_info.path)

      if not api.nvim_buf_is_valid (ref_buf) then
        vim.notify ("Could not create buffer for " .. path_info.path, vim.log.levels.ERROR, {})
        return
      end

      local ok, _ = pcall (function () api.nvim_win_set_buf (win, ref_buf) end)

      if not ok then
        vim.notify ("Buffer is not modifiable", vim.log.levels.ERROR, {})
        return
      end

      if path_info.row ~= nil then
        pcall (function () api.nvim_win_set_cursor (win, { path_info.row, path_info.col }) end)
      end

      vim.notify ("Opened " .. path_info.path, vim.log.levels.INFO, {})
    end
  end)
end

--- Jump to a buffer using a string reference, like `main.c:32`
--- @param ref string
--- @return boolean
function main.jump_buf_by_ref (ref)
  local bufs = vim.api.nvim_list_bufs ()
  local names = {}
  local file, row, col = table.unpack (str.split (ref, ":"))
  local cwd = vim.fn.getcwd ()
  --- @diagnostic disable-next-line: cast-local-type
  row = tonumber (row) or 1
  --- @diagnostic disable-next-line: cast-local-type
  col = tonumber (col) or 1
  local ref_buf = nil
  for i, v in ipairs (bufs) do
    if vim.api.nvim_buf_is_valid (v) then
      names[i] = vim.api.nvim_buf_get_name (v)
      if str.ends_with (names[i], file) then ref_buf = i end
    end
  end
  -- treat reference as path
  if ref_buf == nil then
    local path = vim.fs.normalize (vim.fs.joinpath (cwd, file))
    if main.path_exists_and_is (path, "file") then
      local buf = vim.fn.bufadd (path)

      if buf ~= 0 then ref_buf = buf end
    else
      path = vim.fs.normalize (file)
      if main.path_exists_and_is (path, "file") then
        local buf = vim.fn.bufadd (path)

        if buf ~= 0 then ref_buf = buf end
      end
    end
  end

  if ref_buf == nil then
    vim.notify (
      str.format ("Buffer not found for {}:{}:{}", file, row, col),
      vim.log.levels.INFO,
      {}
    )
    return false
  end

  -- Found
  local win = vim.api.nvim_get_current_win ()
  local buf = vim.api.nvim_get_current_buf ()

  if vim.api.nvim_get_option_value ("filetype", { buf = buf }) == "terminal" then
    vim.api.nvim_win_close (win, true)
    win = vim.api.nvim_get_current_win ()
  end

  if #vim.api.nvim_list_wins () > 1 then
    local selected_win = require ("nvstp.winker.init").select ()
    if selected_win == nil then
      vim.notify ("Invalid selection, try again", vim.log.levels.ERROR, {})
      return false
    end
    win = selected_win.data.winid
  end

  vim.api.nvim_set_option_value ("buflisted", false, { buf = ref_buf })
  vim.api.nvim_win_set_buf (win, ref_buf)
  vim.api.nvim_win_set_cursor (win, {
    row,
    col,
  })

  return true
end

function main.open_visual_selection_ref ()
  if main.is_visual_mode () then
    main.press_esc_key () -- Back to normal mode
    vim.schedule (function ()
      local lines = main.get_visual_selection ()[1]
      local ref = table.unpack (str.split (lines, " "))
      if #ref == 0 then vim.notify ("Empty visual selection", vim.log.levels.ERROR, {}) end
      main.jump_buf_by_ref (ref)
    end)
  else
    vim.notify ("Not in visual mode", vim.log.levels.ERROR, {})
  end
end

--- Returns all complete lines of the visual selection
--
-- Usually used inside vim.schedule(function() <here> end) if v mode is active
--- @return string[]
function main.get_visual_selection_lines ()
  local line_start = vim.api.nvim_buf_get_mark (0, "<")[1]
  local line_end = vim.api.nvim_buf_get_mark (0, ">")[1]
  if line_start == line_end then line_start = line_start - 1 end

  return vim.api.nvim_buf_get_lines (0, line_start - 1, line_end, false)
end

--- Get (only the selected part of) the visual selection line by line and the positions of selection
--
-- Usually used inside vim.schedule(function() <here> end)
--- @return string[] lines
--- @return integer start_line_num
--- @return integer start_col_num
--- @return integer end_line_num
--- @return integer end_col_num
function main.get_visual_selection ()
  local _, sln, scn, _ = table.unpack (vim.fn.getpos ("'<"))
  local _, eln, ecn, _ = table.unpack (vim.fn.getpos ("'>"))

  local lines = vim.api.nvim_buf_get_lines (0, sln - 1, eln, false)

  if sln == eln then
    lines[1] = lines[1]:sub (scn, ecn)
  else
    lines[1] = lines[1]:sub (scn)
    lines[#lines] = lines[#lines]:sub (1, ecn)
  end

  return lines, sln, scn, eln, ecn
end

--- Simple input reading popup window
--- @param opts {title:string?,title_hi:string?,border_hi:string?,width:integer?,height:integer?,callback:fun(text:string)}
function main.simple_input_popup (opts)
  assert (type (opts) == "table", "argument #1 must be a table")
  assert (type (opts.callback) == "function", "callback must be a function")
  local title_value = {
    { opts.title or "", opts.title_hi or "FloatTitle" },
  }
  opts.border_hi = opts.border_hi or "FloatBorder"
  opts.width = opts.width or 50
  opts.height = opts.height or 1

  local buf_id = vim.api.nvim_create_buf (false, true)
  local fwin = vim.api.nvim_open_win (buf_id, true, {
    relative = "editor",
    focusable = true,
    noautocmd = true,
    row = 1,
    col = 1,
    width = opts.width,
    height = opts.height,
    title = title_value,
    style = "minimal",
    border = "rounded",
  })

  local function on_confirm ()
    local buf_text = vim.trim (vim.fn.getline ("."))
    vim.api.nvim_command ("stopinsert")
    vim.api.nvim_win_close (fwin, true)
    vim.api.nvim_buf_delete (buf_id, { force = true })
    opts.callback (buf_text)
  end

  vim.api.nvim_buf_call (buf_id, function () vim.api.nvim_command ("startinsert") end)

  vim.api.nvim_buf_set_keymap (buf_id, "n", "<Esc>", "<cmd>q<CR>", {})
  vim.api.nvim_buf_set_keymap (buf_id, "i", "<Esc>", "<cmd>q<CR>", {})
  vim.api.nvim_buf_set_keymap (buf_id, "n", "<CR>", "", { callback = on_confirm, expr = false })
  vim.api.nvim_buf_set_keymap (buf_id, "i", "<CR>", "", { callback = on_confirm, expr = false })
end

--- `vim.api.nvim_command` wrapper to just print errors as they where called in command-line
--- @param command string
function main.pnvim_command (command)
  local ok, err = pcall (vim.api.nvim_command, command)
  if not ok then
    vim.api.nvim_echo ({ { string.match (tostring (err), ":(E%d-:.+)"), "ErrorMsg" } }, true, {})
  end
end

--- Same as pressing 'y' or 'yy', copy the line or selection to the `+` register
function main.copy ()
  if main.is_visual_mode () then
    main.press_esc_key () -- Back to normal mode
    vim.schedule (function ()
      local lines = main.get_visual_selection ()
      vim.notify ("Copied from " .. #lines .. " line(s)", vim.log.levels.INFO, {})
      vim.fn.setreg ("+", lines)
    end)
  else
    vim.notify ("Copied from 1 line", vim.log.levels.INFO, {})
    vim.fn.setreg ("+", vim.api.nvim_get_current_line ())
  end
end

--- Paste the contents of " register to the cursor position in buffer
function main.paste ()
  if not main.is_buf_modifiable_notify () then return end
  vim.notify ("Paste last copied/yanked text", vim.log.levels.INFO, {})
  local reg_str = tostring (vim.fn.getreg ("+"))
  if reg_str:sub (-1) == "\n" then
    vim.api.nvim_paste (reg_str:sub (1, -2), false, -1)
  else
    vim.api.nvim_paste (reg_str, false, -1)
  end
end

function main.save ()
  if not main.is_buf_named () then
    vim.notify (
      "Buffer is not named, has no associated file. run :w <file_name>",
      vim.log.levels.ERROR,
      {}
    )
    return
  elseif
    vim.bo[vim.fn.bufnr ("%")].buftype:find ("term") ~= nil
    and vim.bo[vim.fn.bufnr ("%")].filetype == "terminal"
  then
    vim.notify (
      "Buffer is a terminal: has no associated file, to save use v mode and run :'<,'>w <file_name>",
      vim.log.levels.ERROR,
      {}
    )
    return
  end
  vim.api.nvim_command ("w!") -- save
  vim.api.nvim_command ("stopinsert") -- back to normal mode
  main.press_esc_key ()
end

function main.quit ()
  if not main.is_buf_modified () then
    -- File is not modified, quit directly
    vim.cmd ("qa!")
  elseif main.is_buf_named () and main.is_buf_modified () then
    -- File has a name, prompt to save before quitting
    local choice = vim.fn.confirm ("Save changes before quitting?", "&Yes\n&No\n&Cancel", 3)

    if choice == 1 then vim.cmd ("wqa!") end
    if choice == 2 then vim.cmd ("qa!") end
  else
    -- File is modified, but no name assigned, prompt to cancel or force quit
    local choice = vim.fn.confirm ("Changes will be lost, quit anyways?", "&Yes\n&No", 2)
    if choice == 1 then vim.cmd ("qa!") end
  end
end

function main.comment ()
  local line_start, line_end
  local ref_position = nil

  if main.is_visual_mode () then
    main.press_esc_key ()
    vim.schedule (function ()
      local _, start_line, _, _ = table.unpack (vim.fn.getpos ("'<"))
      local _, end_line, _, _ = table.unpack (vim.fn.getpos ("'>"))

      line_start = math.min (start_line, end_line)
      line_end = math.max (start_line, end_line)
      require ("vim._comment").toggle_lines (line_start, line_end, ref_position)
    end)
  else
    line_start = vim.fn.line (".")
    line_end = line_start
    require ("vim._comment").toggle_lines (line_start, line_end, ref_position)
  end
end

function main.move_line_up ()
  if not main.is_buf_modifiable_notify () then return end
  vim.api.nvim_command ("move -2")
end

function main.move_line_down ()
  if not main.is_buf_modifiable_notify () then return end
  vim.api.nvim_command ("move +1")
end

function main.resize_win_interact ()
  vim.notify (
    "Reading keys to resize window. To exit, press any key not in: H J K L",
    vim.log.levels.INFO,
    {}
  )
  while true do
    local ok, ch = pcall (vim.fn.getchar) -- Will block exec until we got something
    if
      not ok
      or type (ch) ~= "number"
      -- Upper or lower case h i j k l
      or not ((ch > 71 and ch < 77) or (ch > 103 and ch < 109))
    then
      vim.notify ("Interactive window resizing done", vim.log.levels.INFO, {})
      break
    end
    -- stylua: ignore
    local _ = match (vim.fn.nr2char (ch), true) ({
      -- uppercase 73-76
      H = main.horiz_decsize,
      J = main.vert_decsize,
      K = main.vert_incsize,
      L = main.horiz_incsize,
      -- lowercase 105-108
      h = main.horiz_decsize,
      j = main.vert_decsize,
      k = main.vert_incsize,
      l = main.horiz_incsize,
    })
    vim.api.nvim_command ("redraw")
  end
end

function main.vert_incsize (by)
  local amount = by or 1
  local cur_win = vim.api.nvim_get_current_win ()
  local current_height = vim.api.nvim_win_get_height (cur_win)
  local new_height = math.max (1, current_height + amount) -- Ensures minimum height of 1
  vim.api.nvim_win_set_height (cur_win, new_height)
end

function main.vert_decsize (by)
  local amount = by or 1
  local cur_win = vim.api.nvim_get_current_win ()
  local current_height = vim.api.nvim_win_get_height (cur_win)
  local new_height = math.max (1, current_height - amount) -- Ensures minimum height of 1
  vim.api.nvim_win_set_height (cur_win, new_height)
end

function main.horiz_incsize (by)
  local amount = by or 1
  local cur_win = vim.api.nvim_get_current_win ()
  local current_width = vim.api.nvim_win_get_width (cur_win)
  local new_width = math.max (1, current_width + amount) -- Ensures minimum width of 1
  vim.api.nvim_win_set_width (cur_win, new_width)
end

function main.horiz_decsize (by)
  local amount = by or 1
  local cur_win = vim.api.nvim_get_current_win ()
  local current_width = vim.api.nvim_win_get_width (cur_win)
  local new_width = math.max (1, current_width - amount) -- Ensures minimum width of 1
  vim.api.nvim_win_set_width (cur_win, new_width)
end

function main.undo ()
  if not main.is_buf_modifiable_notify () then return end
  vim.api.nvim_command ("undo")
end

function main.redo ()
  if not main.is_buf_modifiable_notify () then return end
  vim.api.nvim_command ("redo")
end

function main.toggle_vterm () require ("nvstp.term").toggle ("vertical", true) end

function main.toggle_hterm () require ("nvstp.term").toggle ("horizontal", true) end

function main.toggle_fterm () require ("nvstp.term").toggle ("floating", true) end

function main.tab_new () main.pnvim_command ("tabnew") end

function main.tab_prev () main.pnvim_command ("tabprev") end

function main.tab_next () main.pnvim_command ("tabnext") end

function main.tab_close () main.pnvim_command ("tabclose") end

function main.tab_rename ()
  main.simple_input_popup ({
    callback = function (text) main.pnvim_command ("TabRename " .. tostring (text)) end,
    title = "Tab new name",
    title_hi = "AccHiYogurtF",
    border_hi = "AccHiYogurtF",
  })
end

-- Wincker

function main.win_jump () require ("nvstp.winker.init").jump () end

function main.win_close ()
  local res = require ("nvstp.winker.init").select ()
  if res == nil then
    vim.notify ("Could not get selected window", vim.log.levels.ERROR, {})
    return
  end
  if res.data == nil then
    vim.notify (
      "Window with mark: '" .. vim.fn.nr2char (res.char) .. "' does not exist",
      vim.log.levels.ERROR,
      {}
    )
    return
  end

  local win = res.data.winid

  if not vim.api.nvim_win_is_valid (win) then return end
  local buf = vim.api.nvim_win_get_buf (win)

  if not main.is_buf_modified (buf) then
    -- File is not modified, quit directly
    vim.api.nvim_win_close (win, true)
    return
  end

  if main.is_buf_named (buf) then
    -- File has a name, prompt to save before quitting
    local choice = vim.fn.confirm ("Save changes before quitting?", "&Yes\n&No\n&Cancel", 3)

    if choice == 1 then
      vim.api.nvim_buf_call (buf, function () vim.api.nvim_command ("wq!") end)
    end
    if choice == 2 then vim.api.nvim_win_close (win, true) end
  else
    -- File is modified, and no name assigned, prompt to cancel or force quit
    local choice = vim.fn.confirm ("Changes will be lost, quit anyways?", "&Yes\n&No", 2)
    if choice == 1 then vim.api.nvim_win_close (win, true) end
  end
end

-- Scroll the buffer view upcomment (cursor up)
--- @param winnr integer
--- @param lines? number
function main.scroll_up (winnr, lines)
  if lines == nil then lines = 1 end
  local current_cursor = vim.api.nvim_win_get_cursor (winnr)
  local new_cursor = { current_cursor[1] - lines, current_cursor[2] }
  -- Prevent setting the cursor position outside the buffer
  if new_cursor[1] <= 0 then return end
  vim.api.nvim_win_set_cursor (winnr, new_cursor)
end

-- Scroll the buffer view down (cursor down)
--- @param winnr integer
--- @param lines? number
function main.scroll_down (winnr, lines)
  if lines == nil then lines = 1 end
  local buf_size = vim.api.nvim_buf_line_count (vim.api.nvim_win_get_buf (winnr))
  local current_cursor = vim.api.nvim_win_get_cursor (winnr)
  local new_cursor = { current_cursor[1] + lines, current_cursor[2] }
  -- Prevent setting the cursor position outside the buffer
  if new_cursor[1] > buf_size then return end
  vim.api.nvim_win_set_cursor (winnr, new_cursor)
end

-- Find the first floating window with nofile + markdown and scroll
--- @param lines number
function main.scroll_markdown_float (lines)
  local wins = vim.api.nvim_list_wins ()
  for _, win in ipairs (wins) do
    local config = vim.api.nvim_win_get_config (win)
    if config.border ~= nil then -- it's floating
      local buf = vim.api.nvim_win_get_buf (win)
      if vim.bo[buf].buftype == "nofile" and vim.bo[buf].filetype == "markdown" then
        local info = vim.fn.getwininfo (win)[1]
        lines = math.max (info.topline + lines, 1)
        vim.schedule (function ()
          vim.api.nvim_buf_call (
            buf,
            function () main.pnvim_command ("normal! " .. lines .. "zt") end
          )
        end)
        return -- do it on the FIRST match and bounce
      end
    end
  end

  local info = vim.fn.getwininfo (vim.api.nvim_get_current_win ())[1]
  local target = math.max (info.topline + lines, 1)

  main.pnvim_command ("normal! " .. target .. "zt")
end

-- Function to get the appropriate indent string (spaces or tabs)
--- @param count integer?
--- @return string
function main.get_indent_string (count)
  count = count or 1
  if vim.o.expandtab == true then
    return string.rep (" ", vim.o.tabstop * count)
  else
    return string.rep ("\t", count)
  end
end

-- Function to add indentation
function main.add_indent ()
  if not main.is_buf_modifiable_notify () then return end
  local count = vim.v.count1
  local indent_str = main.get_indent_string (count)
  -- Check if Neovim is in visual mode
  if not main.is_visual_mode () then
    -- If not in visual mode, operate on the current line
    local current_line = vim.api.nvim_get_current_line ()
    local new_line = indent_str .. current_line -- Add the appropriate indentation
    vim.api.nvim_set_current_line (new_line)
  else
    -- If in visual mode, operate on the selected range
    main.press_esc_key (vim.fn.mode ()) -- Back to normal mode
    vim.schedule (function () -- Run later to read marks
      local line_start = vim.api.nvim_buf_get_mark (0, "<")[1]
      local line_end = vim.api.nvim_buf_get_mark (0, ">")[1]
      if line_start == line_end then line_start = line_start - 1 end

      -- Iterate over the lines and add indentation
      local lines = vim.api.nvim_buf_get_lines (0, line_start - 1, line_end, false)
      for i, line in pairs (lines) do
        local ln = line_start + (i - 1)
        local new_line = indent_str .. line -- Add the appropriate indentation
        vim.api.nvim_buf_set_lines (0, ln - 1, ln, false, { new_line })
      end
    end)
  end
end

-- Function to remove indentation
function main.remove_indent ()
  if not main.is_buf_modifiable_notify () then return end
  local count = vim.v.count1
  local indent_str = main.get_indent_string (count)
  -- Check if Neovim is in visual mode
  if not main.is_visual_mode () then
    -- If not in visual mode, operate on the current line
    local current_line = vim.api.nvim_get_current_line ()
    local new_line = current_line:gsub ("^" .. indent_str, "") -- Remove leading whitespace or tabs
    vim.api.nvim_set_current_line (new_line)
  else
    -- If in visual mode, operate on the selected range
    main.press_esc_key (vim.fn.mode ()) -- Back to normal mode
    vim.schedule (function () -- Run later to read marks
      local line_start = vim.api.nvim_buf_get_mark (0, "<")[1]
      local line_end = vim.api.nvim_buf_get_mark (0, ">")[1]
      if line_start == line_end then line_start = line_start - 1 end

      -- Iterate over the lines and remove indentation
      local lines = vim.api.nvim_buf_get_lines (0, line_start - 1, line_end, false)
      for i, line in pairs (lines) do
        local ln = line_start + (i - 1)
        local new_line = line:gsub ("^" .. indent_str, "") -- Remove leading whitespace or tabs
        vim.api.nvim_buf_set_lines (0, ln - 1, ln, false, { new_line })
      end
    end)
  end
end

-- Duplicate current visual selection
function main.duplicate_selection ()
  if not main.is_buf_modifiable_notify () then return end
  -- local curpos = vim.fn.getcurpos()
  main.press_esc_key (vim.fn.mode ()) -- Back to normal mode
  vim.schedule (function ()
    local lines, _, _, eln, ecn = main.get_visual_selection ()

    vim.api.nvim_win_set_cursor (0, { eln, ecn - 1 })
    vim.api.nvim_put (lines, "", true, true)
  end)
end

-- Duplicate current line
function main.duplicate_line ()
  if not main.is_buf_modifiable_notify () then return end
  local line_nr, _ = table.unpack (vim.api.nvim_win_get_cursor (0))
  local line_count = math.max (1, vim.v.count)
  local lines = vim.api.nvim_buf_get_lines (0, line_nr - 1, line_nr + line_count - 1, false)
  local last_line = line_nr + line_count - 1
  vim.api.nvim_buf_set_lines (0, last_line, last_line, false, lines)
  -- Set Cursor to duplicated line
  local cursor_line, cursor_col = table.unpack (vim.api.nvim_win_get_cursor (0))
  vim.api.nvim_win_set_cursor (0, { cursor_line + line_count, cursor_col })
end

-- Wrap the visual selection with the characters
--- @param pair table<string>
function main.selection_wrapper (pair)
  if pair == nil then return end -- This never happens with keyboard shortcuts

  -- Get visual selection range
  main.press_esc_key () -- Back to normal mode
  vim.schedule (function ()
    local line_start = vim.fn.getpos ("'<")[2]
    local col_start = vim.fn.getpos ("'<")[3]
    local line_end = vim.fn.getpos ("'>")[2]
    local col_end = vim.fn.getpos ("'>")[3]

    local lines = vim.fn.getline (line_start, line_end)

    local cur_buf = vim.api.nvim_get_current_buf ()
    -- Wrap each line with the specified character at the given columns
    if line_start ~= line_end then -- Multiline
      local ln_strt = lines[1]:sub (1, col_start - 1) .. pair[1] .. lines[1]:sub (col_start)
      vim.api.nvim_buf_set_lines (cur_buf, line_start - 1, line_start, false, { ln_strt })
      local ln_end = lines[#lines]:sub (1, col_end)
        .. pair[2]
        .. lines[#lines]:sub (col_end + 1)
      vim.api.nvim_buf_set_lines (cur_buf, line_end - 1, line_end, false, { ln_end })
    else -- One line
      local ln = lines[1]:sub (1, col_start - 1)
        .. pair[1]
        .. lines[1]:sub (col_start, col_end)
        .. pair[2]
        .. lines[1]:sub (col_end + 1)
      vim.api.nvim_buf_set_lines (cur_buf, line_start - 1, line_start, false, { ln })
    end
  end)
end

--- Read a character and wrap the selection with it (and their pair)
function main.wrap_selection ()
  local pairs = {
    ['"'] = { '"', '"' },
    ["'"] = { "'", "'" },
    ["`"] = { "`", "`" },
    ["("] = { "(", ")" },
    ["{"] = { "{", "}" },
    ["["] = { "[", "]" },
    ["<"] = { "<", ">" },
    ["?"] = { "¿", "?" },
    ["!"] = { "¡", "!" },
  }
  local ok, ch = pcall (vim.fn.getchar) -- Will block exec until we got something
  --- @cast ch integer
  if not ok then vim.notify ("Failed to get character", vim.log.levels.ERROR, {}) end
  local char = vim.fn.nr2char (ch)
  if not ("\"'`(){}[]<>¿?¡!"):has (char) then
    vim.notify (
      str.format ("Cannot wrap selection with {} ({})", char, ch),
      vim.log.levels.ERROR,
      {}
    )
    return
  end
  main.selection_wrapper (pairs[char])
end

-- Give all functions a name for debugging purposes
-- for name, fun in pairs(main) do
--   main[name] = setmetatable({ func = fun }, {
--     __call = function(me, ...) return me.func(...) end,
--     __tostring = function() return name end,
--   })
-- end

function main.add_toggle_hlmatch ()
  local current_search = vim.fn.getreg ("/")
  local is_visible = vim.v.hlsearch == 1

  vim.schedule (function ()
    local new_search = vim.fn.getreg ("/")
    if is_visible and new_search == current_search then
      vim.api.nvim_command("nohlsearch")
    end
  end)

  return "*"
end

return main
