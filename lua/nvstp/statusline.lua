local dev_icons_loaded, devicons = pcall (require, "nvim-web-devicons")

local vim_modes = {
  ["n"] = { "NORMAL", "normal" },
  ["no"] = { "NORMAL (no)", "normal" },
  ["nov"] = { "NORMAL (nov)", "normal" },
  ["noV"] = { "NORMAL (noV)", "normal" },
  ["noCTRL-V"] = { "NORMAL", "normal" },
  ["niI"] = { "NORMAL i", "normal" },
  ["niR"] = { "NORMAL r", "normal" },
  ["niV"] = { "NORMAL v", "normal" },

  ["nt"] = { "NTERMINAL", "normal" },
  ["ntT"] = { "NTERMINAL (ntT)", "normal" },

  ["v"] = { "VISUAL", "visual" },
  ["vs"] = { "V-CHAR (Ctrl O)", "visual" },
  ["V"] = { "V-LINE", "visual" },
  ["Vs"] = { "V-LINE", "visual" },
  [""] = { "V-BLOCK", "visual" },

  ["i"] = { "INSERT", "insert" },
  ["ic"] = { "INSERT [CMP]", "insert" },
  ["ix"] = { "INSERT [cmp]", "insert" },

  ["t"] = { "TERMINAL", "prompt" },

  ["R"] = { "REPLACE", "replace" },
  ["Rc"] = { "REPLACE (Rc)", "replace" },
  ["Rx"] = { "REPLACEa (Rx)", "replace" },
  ["Rv"] = { "V-REPLACE", "replace" },
  ["Rvc"] = { "V-REPLACE (Rvc)", "replace" },
  ["Rvx"] = { "V-REPLACE (Rvx)", "replace" },

  ["s"] = { "SELECT", "visual" },
  ["S"] = { "S-LINE", "visual" },
  [""] = { "S-BLOCK", "visual" },

  ["c"] = { "COMMAND", "prompt" },
  ["cv"] = { "COMMAND", "prompt" },
  ["ce"] = { "COMMAND", "prompt" },
  ["r"] = { "PROMPT", "prompt" },
  ["rm"] = { "MORE", "prompt" },
  ["r?"] = { "CONFIRM", "prompt" },
  ["x"] = { "CONFIRM", "prompt" },
  ["!"] = { "SHELL", "prompt" },

  ["sp"] = { "NVSTP", "other" },
}

local main = {}
local blocks = {}

function blocks.mode (bar, v)
  local mode, color = table.unpack (vim_modes[v.mode] or { "UNK", "other" })
  bar (main.colors.mode[color], " " .. mode)
end

function blocks.file (bar, v)
  local icon = "󰈚 "
  local file = (#v.name > 0 and vim.fs.basename (v.name)) or "<new>"

  if file ~= "<new>" then
    if dev_icons_loaded then icon = devicons.get_icon (file) or icon end
  end

  local is_readonly = vim.bo.readonly
  local is_modified = vim.bo.modified

  local color = main.colors.file.normal
  if is_readonly then
    color = main.colors.file.readonly
  elseif is_modified then
    color = main.colors.file.modified
  end

  bar (
    color,
    string.format ("%s %s [#%d]", icon, file, vim.fn.bufnr ("%"))
    .. (is_modified and " " or "")
  )
end

function blocks.file_type (bar, v) bar (main.colors.file.type, v.bfft) end

function blocks.file_eol (bar, v)
  bar (main.colors.file.eol, (vim.bo[v.sbuf].fileformat == "unix") and " " or " ")
end

function blocks.file_encoding (bar, v)
  local enc = vim.bo[v.sbuf].fileencoding
  if enc ~= "" then bar (main.colors.file.enc, enc) end
end

function blocks.cursor_pos (bar, _) bar (main.colors.cursor_pos, "(%p%%) %c:%l/%L [%b][0x%B]") end

function blocks.lsp_name (bar, v)
  if v.ilsp then
    local sbuf = v.sbuf
    for _, lsp in ipairs (vim.lsp.get_clients ({ bufnr = sbuf })) do
      if lsp.name ~= "null-ls" and lsp.attached_buffers[sbuf] ~= nil then
        bar (main.colors.lsp.name, "  " .. lsp.name)
        break
      end
    end
  end
end

function blocks.lsp_diag (bar, v)
  if v.ilsp then
    local sbuf = v.sbuf
    local i, h, w, e
    i = #vim.diagnostic.get (sbuf, { severity = vim.diagnostic.severity.INFO })
    h = #vim.diagnostic.get (sbuf, { severity = vim.diagnostic.severity.HINT })
    w = #vim.diagnostic.get (sbuf, { severity = vim.diagnostic.severity.WARN })
    e = #vim.diagnostic.get (sbuf, { severity = vim.diagnostic.severity.ERROR })
    --         |
    if i and i > 0 then bar (main.colors.lsp.info, " " .. tostring (i)) end
    if h and h > 0 then bar (main.colors.lsp.hint, " " .. tostring (h)) end
    if w and w > 0 then bar (main.colors.lsp.warn, " " .. tostring (w)) end
    if e and e > 0 then bar (main.colors.lsp.error, " " .. tostring (e)) end
  end
end

function blocks.git_branch (bar, v)
  if v.igit ~= nil then bar (main.colors.git.branch, " " .. v.igit) end
end

function blocks.git_stat (bar, v)
  if v.igit then
    local gst = vim.b[v.sbuf].gitsigns_status_dict
    if gst == nil then return end
    if gst.added and gst.added > 0 then
      bar (main.colors.git.added, " " .. tostring (gst.added))
    end
    if gst.changed and gst.changed > 0 then
      bar (main.colors.git.changed, " " .. tostring (gst.changed))
    end
    if gst.removed and gst.removed > 0 then
      bar (main.colors.git.removed, " " .. tostring (gst.removed))
    end
  end
end

function blocks.cwd (bar, _) bar (main.colors.cwd, "󰉖 " .. vim.fs.basename (vim.fn.getcwd ())) end

function blocks.truncate (bar, v)
  v.skip = true
  bar (nil, "%#StatusLine#%<")
end

function blocks.shift_to_end (bar, v)
  v.swap = true
  bar (nil, "%#StatusLine#%=")
end

function main.run ()
  if #main.bar < 1 then return "" end
  local env = {}

  env.sbuf = vim.api.nvim_win_get_buf (vim.g.statusline_winid)
  env.bfft = vim.bo[env.sbuf].filetype
  env.mode = vim.api.nvim_get_mode ().mode
  if string.has (main.ignore, env.bfft) then
    return vim_modes[env.mode][1] .. " in " .. env.bfft .. "%<%=%c:%l/%L [%b][0x%B]"
  elseif vim.api.nvim_get_current_win () ~= vim.g.statusline_winid then
    return "  INACTIVE"
      .. (#env.bfft > 0 and (" in " .. env.bfft) or "")
      .. "%<%=%c:%l/%L [%b][0x%B]"
  end

  env.name = vim.fn.bufname (env.sbuf)
  env.igit = vim.b[env.sbuf].gitsigns_head
  env.ilsp = rawget (vim, "lsp") ~= nil
  env.swap = false
  env.skip = false
  local sep = main.separators.l

  local function color_and_unions_r (last, curr, id)
    local hg_name = "NvstpSL" .. id

    if curr == nil then
      if last == nil then return "" end
      vim.api.nvim_set_hl (0, hg_name, { fg = last.bg })
      return "%#" .. hg_name .. "#" .. sep
    end

    vim.api.nvim_set_hl (0, hg_name, curr)
    if last == nil then return "%#" .. hg_name .. "# " end
    vim.api.nvim_set_hl (0, hg_name .. "S", { fg = last.bg, bg = curr.bg })
    return "%#" .. hg_name .. "S#" .. sep .. "%#" .. hg_name .. "# "
  end

  local function color_and_unions_l (last, curr, id)
    local hg_name = "NvstpSL" .. id

    if curr == nil then
      if last == nil then return "" end
      vim.api.nvim_set_hl (0, hg_name, { bg = last.bg })
      return "%#" .. hg_name .. "#" .. sep
    end

    vim.api.nvim_set_hl (0, hg_name, curr)
    if last == nil then return " %#" .. hg_name .. "#" end
    vim.api.nvim_set_hl (0, hg_name .. "S", { bg = last.bg, fg = curr.bg })
    return " %#" .. hg_name .. "S#" .. sep .. "%#" .. hg_name .. "#"
  end

  local color_and_unions = color_and_unions_r

  --- @type string|table
  local bar = {}
  local function bar_element (c, s)
    local i = #bar
    bar[i + 1] = c
    bar[i + 2] = s
  end

  local line = ""
  local last_hg = nil
  for h, fun in ipairs (main.bar) do
    if blocks[fun] == nil then goto continue end
    blocks[fun] (bar_element, env)
    for i = 1, #bar, 1 do
      local it = bar[i]
      if i % 2 == 0 then
        line = line .. it
      else
        if env.skip then
          env.skip = false
        else
          line = line
            .. color_and_unions (
              last_hg,
              it,
              fun:gsub ("^(.)", string.upper) .. tostring (h + i)
            )
          last_hg = it
        end
        if env.swap then
          last_hg = {}
          sep = main.separators.r
          color_and_unions = color_and_unions_l
          env.swap = false
        end
      end
    end
    ::continue::
    bar = {}
  end
  return line .. " "
end

function main.set (opts, enable)
  main = vim.tbl_deep_extend ("force", main, opts)
  vim.api.nvim_set_hl (0, "StatusLineNC", main.colors.inactive)
  StatusLineGenerate = main.run

  main.__enabled = not enable
  vim.api.nvim_create_user_command ("NvstpSLToggle", function ()
    if main.__enabled then
      vim.opt.statusline = ""
      main.__enabled = false
    else
      vim.opt.statusline = "%!v:lua.StatusLineGenerate()"
      main.__enabled = true
    end
  end, {})
  vim.api.nvim_command ("NvstpSLToggle")
end

return main
