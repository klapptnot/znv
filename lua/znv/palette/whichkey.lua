local core = require ("znv.palette.core")
local str = require ("warm.str")
local tbl = require ("warm.table")

--- @alias NWhichKeyOpts { prefill?: string, ignore?: string|string[], hl?: { Prefix?: vim.api.keyset.highlight, Fuzzy?: vim.api.keyset.highlight, Char?: vim.api.keyset.highlight, Tags?: vim.api.keyset.highlight, Match?: vim.api.keyset.highlight, Stats?: vim.api.keyset.highlight, Title?: vim.api.keyset.highlight }, title?: string }

--- @class NWhichKey
local main = {
  --- @type NWhichKeyOpts
  opts = {
    prefill = " ",
    ignore = {
      "whichkey.ignored",
    },
    hl = {
      Prefix = { fg = "#fff3d7" },
      Fuzzy = { fg = "#ffbaf1" },
      Char = { fg = "#a0eaff" },
      Tags = { fg = "#a4f4a6" },
      Match = { fg = "#f0d0ff", bg = "#47374b" },
      Stats = { fg = "#5adf9d" },
    },
    title = "Whichkey",
  },
}

local function token_backward (winid, delete)
  local row, col = table.unpack (vim.api.nvim_win_get_cursor (winid))
  local line =
    vim.api.nvim_buf_get_lines (vim.api.nvim_win_get_buf (winid), row - 1, row, false)[1]
  local prefix = line:sub (1, col)

  local len = 1
  if prefix:sub (-1) == ">" then
    for i = #prefix, 1, -1 do
      if prefix:sub (i, i) == "<" then
        len = #prefix - i + 1
        break
      end
    end
  end

  local start_col = math.max (0, col - len)
  if delete then
    local new_line = line:sub (1, start_col) .. line:sub (col + 1)
    vim.api.nvim_buf_set_lines (
      vim.api.nvim_win_get_buf (winid),
      row - 1,
      row,
      false,
      { new_line }
    )
  end

  vim.api.nvim_win_set_cursor (winid, { row, start_col })
end

local function token_forward (winid, delete)
  local row, col = table.unpack (vim.api.nvim_win_get_cursor (winid))
  local line =
    vim.api.nvim_buf_get_lines (vim.api.nvim_win_get_buf (winid), row - 1, row, false)[1]
  local suffix = line:sub (col + 1)

  local len = 1
  if suffix:sub (1, 1) == "<" then
    for i = 1, #suffix do
      if suffix:sub (i, i) == ">" then
        len = i
        break
      end
    end
  end

  if delete then
    local end_col = math.min (#line, col + len)
    local new_line = line:sub (1, col) .. line:sub (end_col + 1)
    vim.api.nvim_buf_set_lines (
      vim.api.nvim_win_get_buf (winid),
      row - 1,
      row,
      false,
      { new_line }
    )
    return
  end

  vim.api.nvim_win_set_cursor (winid, { row, col + len })
end

local function make_results_pref (mapps, pref, width)
  local lines = {}
  local keys = {}
  local fmt = "{1: =>2} | {2: =<11} ➜ {3: =<" .. width - 19 .. "}"
  for n, v in pairs (mapps) do
    if str.starts_with (n, pref) then
      lines[#lines+1] =
        str.format (fmt, v.mode .. (v.buffer == 1 and "-" or "+"), n:sub (#pref + 1), v.desc)
      keys[#keys+1] = n
    end
  end
  return lines, keys, "(:?| )[.]"
end

local function make_results_fuzz (mapps, fuzz, width)
  local lines = {}
  local keys = {}
  local fmt = "{1: =<" .. width - 19 .. "} ➜ {2: =<11} | {3: =>2}"
  for n, v in pairs (mapps) do
    if str.fuzzy (v.desc, fuzz) then
      lines[#lines+1] = str.format (fmt, v.desc, n, v.mode .. (v.buffer == 1 and "-" or "+"))
      keys[#keys+1] = n
    end
  end
  return lines, keys, "[" .. fuzz .. "]"
end

local function get_mapps ()
  local bmaps = vim.api.nvim_buf_get_keymap (0, "n")
  local gmaps = vim.api.nvim_get_keymap ("n")

  local res = {}
  for _, v in ipairs (gmaps) do
    if v.desc ~= nil and not str.starts_with (v.lhs, "<Plug>") then
      local lhs = string.gsub (v.lhs, " ", "<Space>")
      res[lhs] = v
      v.buffer = 0
    end
  end
  for _, v in ipairs (bmaps) do
    if v.desc ~= nil and not str.starts_with (v.lhs, "<Plug>") then
      local lhs = string.gsub (v.lhs, " ", "<Space>")
      res[lhs] = v
      v.buffer = 1
    end
  end
  return res
end

local function whichkey ()
  local mapps = get_mapps ()
  if tbl.is_empty (mapps) then return end
  local ns = vim.api.nvim_create_namespace ("znv-palette-whichkey")
  local fuzzs_ns = vim.api.nvim_create_namespace ("znv-palette-whichkey-fuzzs")
  local em_fmt = "{}/" .. #tbl.get_keys (mapps)

  local close_palette, props = core.open ({ title = main.opts.title, ww = 65 })

  if props == nil then
    vim.notify ("Could not open a new palette", vim.log.levels.ERROR, { "Whichkey" })
    return
  end
  --- @cast close_palette function

  local function close_whichkey ()
    vim.on_key (nil, ns, {})
    close_palette ()
  end
  local make_results = make_results_pref

  local fuzzy = false
  local selected = -1
  local em_id = nil
  local mm_id = nil

  local function set_window_style (hl)
    vim.api.nvim_set_option_value (
      "winhighlight",
      "FloatBorder:" .. hl,
      { win = props.display.win }
    )
    vim.api.nvim_set_option_value (
      "winhighlight",
      "FloatBorder:" .. hl,
      { win = props.input.win }
    )
  end

  local function check_match (lines, keys, run)
    if fuzzy then
      if not run then return false, nil end
      if #keys == 0 then return nil, nil end
      selected = selected + 1 -- 1 based
      if selected == 0 or mapps[keys[selected]] == nil then -- nothing selected, or nil
        selected = 1
      end
      return true, mapps[keys[selected]]
    else
      if #lines > 0 then
        -- Run top match
        if run then return true, mapps[keys[1]] end
        -- If len is 0, user typed the whole mapping
        if #str.split (lines[1], " ")[3] == 0 then return true, mapps[keys[1]] end
      end
      return false, nil
    end
  end

  local function on_select_keymap (mapp, state)
    if mapp == nil then
      vim.notify ("Somehow mapping is nil, lol", vim.log.levels.ERROR, { title = "Whichkey" })
    end
    local s = {
      win = vim.api.nvim_get_current_win (),
      buf = vim.api.nvim_get_current_buf (),
      mod = vim.api.nvim_get_mode ().mode:lower ():sub (1, 1),
    }
    if state.win ~= s.win or state.buf ~= s.buf or state.mod ~= s.mod then return end

    local count = vim.api.nvim_get_vvar ("count1")
    if type (mapp.callback) == "function" then
      for _ = 1, count, 1 do
        mapp.callback ()
      end
    else
      local rhs = mapp.rhs
      if mapp.expr == 1 then rhs = vim.api.nvim_eval (rhs) end
      if count ~= 1 then rhs = tostring (count) .. rhs end

      vim.api.nvim_feedkeys (
        vim.api.nvim_replace_termcodes (rhs, true, false, true),
        mapp.noremap == 0 and "n" or "m",
        false
      )
    end
  end

  local function handle_updates (run)
    local line = vim.api.nvim_buf_get_lines (props.input.buf, 0, 1, false)[1]
    local lines, keys, match = make_results (mapps, str.strip (line), props.width)
    local found, mapp = check_match (lines, keys, run)
    if found == nil then
      close_whichkey ()
      return
    end
    if found then
      local state = props.state
      close_whichkey ()
      vim.schedule (function () on_select_keymap (mapp, state) end)
      return true
    end

    vim.api.nvim_win_call (props.display.win, function ()
      if mm_id ~= nil then vim.fn.matchdelete (mm_id) end
      mm_id = vim.fn.matchadd ("NWhichKeyMatch", match)
    end)

    if #lines > 0 then core.resizeh (props.display, #lines) end

    vim.api.nvim_set_option_value ("modifiable", true, { buf = props.display.buf })
    vim.api.nvim_buf_set_lines (props.display.buf, 0, -1, true, lines)
    vim.api.nvim_set_option_value ("modifiable", false, { buf = props.display.buf })

    vim.api.nvim_buf_set_extmark (props.input.buf, ns, 0, 0, {
      virt_text = { { str.format (em_fmt, #lines), "NWhichKeyStats" } },
      virt_text_pos = "right_align",
      hl_mode = "combine",
      id = em_id,
    })
    return false
  end

  local function on_key_handler (key, typed)
    -- or (typed:sub(1, 1) == "\r" and #typed == 2)
    if typed:sub (2) == key then typed = typed:sub (2) end
    local key_repr = vim.fn.keytrans (typed)

    if fuzzy then
      if key_repr == "<C-Esc>" then
        local line = vim.api.nvim_buf_get_lines (props.input.buf, 0, 1, false)[1]
        if line == "" then
          make_results = make_results_pref
          set_window_style ("NWhichKeyPrefix")
          fuzzy = false
        else
          require ("notify") ("Clear line", vim.log.levels.INFO, {})
          vim.api.nvim_buf_set_lines (props.input.buf, 0, -1, false, {})
        end
        handle_updates (false)
        return ""
      end
      if key_repr == "<CR>" then
        handle_updates (true)
        return ""
      end
      if key_repr == "<Esc>" then
        close_whichkey ()
        return ""
      end
      local max = props.display.cur_h - 1
      local new_sel = nil
      if key_repr == "<Up>" then
        new_sel = math.max (math.min (selected - 1, max), 0)
        if selected == new_sel then new_sel = max end -- min -> wrap
      elseif key_repr == "<Down>" then
        new_sel = math.min (math.max (selected + 1, 0), max)
        if selected == new_sel then new_sel = 0 end -- max -> wrap
      else
        vim.schedule (handle_updates) -- update after return
        return
      end
      selected = new_sel
      vim.api.nvim_buf_clear_namespace (props.display.buf, fuzzs_ns, 0, -1)
      vim.hl.range (
        props.display.buf,
        fuzzs_ns,
        "NWhichKeyMatch",
        { selected, 0 },
        { selected, -1 }
      )
      return ""
    end

    local functional_keys = {
      -- these keys should trigger handle_updates
      ["<BS>"] = true,
      ["<lt>"] = true,
      ["<gt>"] = true,
      -- these keys are ignored
      ["<Left>"] = false,
      ["<Right>"] = false,
      ["<Home>"] = false,
      ["<kHome>"] = false,
      ["<End>"] = false,
      ["<kEnd>"] = false,
      ["<ScrollWheelUp>"] = false,
      ["<ScrollWheelDown>"] = false,
      ["<ScrollWheelLeft>"] = false,
      ["<ScrollWheelRight>"] = false,
    }

    if functional_keys[key_repr] == true then
      -- schedule to run after that key made a change
      vim.schedule (handle_updates)
      return
    end
    if functional_keys[key_repr] == false then return end

    if key_repr == "<Esc>" then
      close_whichkey ()
      return "" -- nvim ignores this key when empty string is returned
    elseif key_repr == "<CR>" then
      handle_updates (true)
      return ""
    elseif key_repr == "<C-Esc>" then
      local line = vim.api.nvim_buf_get_lines (props.input.buf, 0, 1, false)[1]
      if line == "" then
        -- we are not in fuzzy mode
        make_results = make_results_fuzz
        set_window_style ("NWhichKeyFuzzy")
        fuzzy = true
      else
        vim.api.nvim_buf_set_lines (props.input.buf, 0, -1, false, {})
      end
    elseif key_repr == "<C-BS>" then
      token_backward (props.input.win, true)
    elseif key_repr == "<C-Del>" then
      token_forward (props.input.win, true)
    elseif key_repr == "<C-Left>" then
      token_backward (props.input.win, false)
    elseif key_repr == "<C-Right>" then
      token_forward (props.input.win, false)
    else -- keys could be inserted for insert mode, return ""
      local row, col = table.unpack (vim.api.nvim_win_get_cursor (props.input.win))
      local line = vim.api.nvim_buf_get_lines (props.input.buf, row - 1, row, false)[1]

      local new_line = line:sub (1, col) .. key_repr .. line:sub (col + 1)
      vim.api.nvim_buf_set_lines (props.input.buf, row - 1, row, false, { new_line })
      vim.api.nvim_win_set_cursor (props.input.win, { row, col + #key_repr })
    end
    handle_updates (false)
    return "" -- nvim ignores...
  end

  if #main.opts.prefill > 0 then
    vim.api.nvim_buf_set_lines (props.input.buf, 0, -1, true, { main.opts.prefill })
    vim.api.nvim_win_set_cursor (props.input.win, { 1, #main.opts.prefill })
  end

  set_window_style ("NWhichKeyPrefix")

  vim.api.nvim_win_call (props.display.win, function ()
    vim.fn.matchadd ("NWhichKeyTags", "\\[[^\\]]*\\]")
    vim.fn.matchadd ("NWhichKeyChar", "[➜|]")
  end)

  em_id = vim.api.nvim_buf_set_extmark (props.input.buf, ns, 0, 0, {
    virt_text = { { "", "NWhichKeyStats" } },
    virt_text_pos = "right_align",
    hl_mode = "combine",
  })

  -- schedule to prevent autocmd feedkeys????
  vim.schedule (function ()
    vim.on_key (on_key_handler, ns, {})
    handle_updates (false)
  end)
end

--- Set up whichkey
--- @param opts? NWhichKeyOpts
--- @return NWhichKey
function main.setup (opts)
  main.opts = vim.tbl_deep_extend ("force", main.opts, opts or {})
  if type (main.opts.ignore) == "table" then
    --- @diagnostic disable-next-line: param-type-mismatch
    main.opts.ignore = table.concat (main.opts.ignore, ",")
  end
  main.opts.prefill = main.opts.prefill and vim.fn.keytrans (main.opts.prefill) or ""
  main.opts.title = str.format (" {} ", main.opts.title)

  local function set_hl_groups (_)
    for name, color in pairs (main.opts.hl or {}) do
      vim.api.nvim_set_hl (0, "NWhichKey" .. name, color)
    end
  end

  set_hl_groups ()

  vim.api.nvim_create_autocmd ("ColorScheme", {
    callback = set_hl_groups,
  })

  return main
end

--- Map Whichkey to a normal nvim mapping
--- @param key string
function main.map (key)
  vim.api.nvim_set_keymap ("n", key, "", {
    callback = whichkey,
    nowait = true,
    silent = true,
    noremap = true,
  })
end

return main
