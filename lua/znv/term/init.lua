local tbl = require ("warm.table")

local main = {
  opts = {},
  instances = {},
  total = 0,
}

--- Make sure that always a valid layout is defined
--- @param layout string
--- @return string
function main.ensure_layout (layout)
  -- local l = tbl.contains({"horizontal", "vertical", "floating"}, layout)
  -- This is faster than checking any way with if's or loops
  if
    ({
      ["horizontal"] = 0,
      ["vertical"] = 0,
      ["floating"] = 0,
    })[layout] == nil
  then
    layout = "horizontal"
  end
  return layout
end

function main.create_win (layout)
  ({
    vertical = function ()
      local size = math.floor (vim.api.nvim_win_get_width (0) * main.opts.layout.vertical.w)
      vim.api.nvim_command (main.opts.layout.vertical.p .. " " .. size .. " vsplit")
    end,
    horizontal = function ()
      local size = math.floor (vim.api.nvim_win_get_height (0) * main.opts.layout.horizontal.h)
      vim.api.nvim_command (main.opts.layout.horizontal.p .. " " .. size .. " split")
    end,
    floating = function ()
      local fsty = main.opts.layout.floating
      vim.api.nvim_open_win (0, true, {
        relative = "editor", -- Use the editor grid, not the window grid
        row = math.floor ((vim.o.lines - (fsty.h * vim.o.lines)) / 2),
        col = math.floor ((vim.o.columns - (fsty.w * vim.o.columns)) / 2),
        height = math.ceil (fsty.h * vim.o.lines),
        width = math.ceil (fsty.w * vim.o.columns),
        border = fsty.s,
      })
      vim.wo.winhighlight = "FloatBorder:Type"
    end,
  })[layout] () -- Create window
  if main.opts.no_line_nums == true then
    vim.wo.relativenumber = false -- Disable relativenumber for this window
    vim.wo.number = false -- Disable line number for this window
  end
  return vim.api.nvim_get_current_win () -- return current window
end

function main.new (layout)
  layout = main.ensure_layout (layout)
  local win = main.create_win (layout)
  local buf = vim.api.nvim_create_buf (true, true) -- New buffer
  vim.api.nvim_set_option_value ("filetype", "terminal", { buf = buf }) -- Set as a nvim terminal
  vim.api.nvim_set_option_value ("buflisted", false, { buf = buf }) -- Set as unlisted/hidden
  vim.api.nvim_win_set_buf (win, buf) -- Attach the buffer to window

  local shell = main.opts.shell or vim.o.shell
  local job = vim.fn.jobstart (shell, { term = true })

  local instance_key = "inst_" .. tostring (main.total)
  -- Set the info to the main.instances[layout] table
  main.instances[instance_key] = {
    lay = layout,
    sid = instance_key,
    vis = true, -- Whether the window is visible
    buf = buf, -- The terminal buffer attached
    win = win, -- The window id
    job = job, -- Shell job id
    mod = "i", -- The current vim mode from the window
  }
  main.total = main.total + 1
  -- Start on insert mode
  if vim.v.count ~= 1 then vim.api.nvim_command ("startinsert") end
end

function main.hide (keyname)
  -- Terminal can be closed using the shell, and this way doesn't
  -- change our info, check if buf and win are valid to close or
  -- start a new one because it's already closed
  local vb, vw = nil, nil
  vb = vim.api.nvim_buf_is_valid (main.instances[keyname].buf)
  vw = vim.api.nvim_win_is_valid (main.instances[keyname].win)
  if not (vb and vw) then
    local layout = main.instances[keyname].lay -- Save layout
    main.instances[keyname] = nil -- empty keyname to use it again
    main.new (layout)
    return
  end
  local all_wins = vim.api.nvim_list_wins ()
  if #all_wins == 1 and all_wins[1] == main.instances[keyname].win then
    return
  end
  vim.api.nvim_win_close (main.instances[keyname].win, true)
  main.instances[keyname].vis = false
  -- Disable insertion mode (Useless most of the time)
  vim.api.nvim_buf_call (
    main.instances[keyname].buf,
    function () vim.api.nvim_command ("stopinsert") end
  )
end

function main.show (keyname)
  local vb = nil
  vb = vim.api.nvim_buf_is_valid (main.instances[keyname].buf)
  if not vb then
    local layout = main.instances[keyname].lay -- Save layout to use
    main.instances[keyname] = nil -- empty keyname to use it again
    main.new (layout)
    return
  end
  main.instances[keyname].win = main.create_win (main.instances[keyname].lay)
  main.instances[keyname].vis = true -- Is visible now
  vim.api.nvim_win_set_buf (main.instances[keyname].win, main.instances[keyname].buf)
end

function main.close (keyname)
  local vb, vw = nil, nil
  vb = vim.api.nvim_buf_is_valid (main.instances[keyname].buf)
  vw = vim.api.nvim_win_is_valid (main.instances[keyname].win)
  if vw then vim.api.nvim_win_close (main.instances[keyname].win, true) end
  if vb then vim.api.nvim_buf_delete (main.instances[keyname].buf, { force = true }) end
  vim.fn.jobstop (main.instances[keyname].job)
  main.instances[keyname] = nil
  main.total = main.total - 1
end

--- Toggle (or optionally focus -- if not already -- instead of closing) terminal window
--- Can start insert mode if desired, add `true` as #3 argument
--- @param layout "horizontal"|"vertical"|"floating"
--- @param focus? boolean
--- @param norm? boolean
function main.toggle (layout, focus, norm)
  if type (focus) == "nil" then focus = false end
  assert (type (focus) == "boolean", "argument #2 to 'toggle' must be a boolean")
  if type (norm) == "nil" then norm = false end
  assert (type (norm) == "boolean", "argument #3 to 'toggle' must be a boolean")
  layout = main.ensure_layout (layout)
  local is_lay = function (_, v) return layout == v.lay end
  local fints = tbl.filter (main.instances, is_lay, false)
  if tbl.is_empty (fints) then
    main.new (layout)
    return
  end
  local fint_k = tbl.get_keys (fints)[1]
  local fint = fints[fint_k]
  local valid_win = vim.api.nvim_win_is_valid (fint.win)

  -- show instance if it is not valid or visible
  if not fints[fint_k].vis or not valid_win then
    main.show (fint_k)
    if not norm then vim.api.nvim_command ("startinsert") end
    return
  end

  -- a terminal window should be open
  local is_focused = vim.api.nvim_get_current_win () == fints[fint_k].win

  if is_focused then
    main.hide (fint_k)
    return
  end

  if focus then
    vim.api.nvim_set_current_win (fints[fint_k].win)
    if not norm then vim.api.nvim_command ("startinsert") end
    return
  end

  -- openned, unfocused, close instead
  main.hide (fint_k)
end

function main.debug (layout)
  layout = main.ensure_layout (layout)
  local is_lay = function (_, v) return layout == v.lay end
  return tbl.filter (main.instances, is_lay, false)
end

function main.toggle_all (layout)
  local tab = main.instances
  if layout ~= nil then
    layout = main.ensure_layout (layout)
    local is_lay = function (_, v) return layout == v.lay end
    tab = tbl.filter (main.instances, is_lay, false)
  end
  for k, _ in pairs (tab) do
    if main.instances[k].vis then
      main.hide (k) -- Hide instance
    elseif not main.instances[k].vis then
      main.show (k) -- Show instance
    end
  end
end

function main.close_all (layout)
  local tab = main.instances
  if layout ~= nil then
    layout = main.ensure_layout (layout)
    local is_lay = function (_, v) return layout == v.lay end
    tab = tbl.filter (main.instances, is_lay, false)
  end
  for k, _ in pairs (tab) do
    main.close (k)
  end
end

function main.setup (opts)
  opts = opts or {}
  main.opts = tbl.deep_merge ({
    send_keys = true, -- Send all pressed keys to terminal window
    no_line_nums = true, -- Turn off line numbers if they are turned on
    layout = {
      floating = {
        s = "rounded", -- Border style
        h = 0.75, -- Height of floating window N/100
        w = 0.75, -- Width of floating window N/100
      },
      horizontal = {
        p = "rightbelow", -- Position of horizontal window
        h = 0.4, -- Height of horizontal window N/100
      },
      vertical = {
        p = "rightbelow", -- Position of vertical window
        w = 0.4, -- Width of vertical window N/100
      },
    },
  }, opts)
  return main
end

return main
