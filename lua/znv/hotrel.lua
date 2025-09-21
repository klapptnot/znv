local tbl = require ("warm.table")
local main = {}
local hot_buffers = {}

local function load_and_run (filepath)
  --- @diagnostic disable-next-line: undefined-field
  if not vim.uv.fs_stat (filepath) then
    vim.notify ("🚫 Could not open file: " .. filepath, vim.log.levels.ERROR)
    return
  end

  local chunk, err = loadfile (filepath, "t")
  if chunk == nil or err ~= nil then
    vim.notify ("💥 Load error:\n" .. err, vim.log.levels.ERROR)
    return
  end

  local ok, result = pcall (chunk)
  if not ok then
    vim.notify ("💣 Runtime error:\n" .. result, vim.log.levels.ERROR)
    return
  end

  if type (result) == "table" and result.setup then
    result.setup ()
  elseif type (result) == "function" then
    result ()
  end

  vim.notify ("✨ HotReloaded: " .. filepath, vim.log.levels.INFO)
end

local group = vim.api.nvim_create_augroup ("HotReloadGroup", { clear = false })

local function enable_reload (buf)
  local path = vim.api.nvim_buf_get_name (buf)
  if path == "" then
    vim.notify ("❌ Buffer has no path", vim.log.levels.ERROR)
    return
  end
  if hot_buffers[buf] then
    vim.notify ("🌀 Already hot-reloading: " .. path, vim.log.levels.WARN)
    return
  end
  hot_buffers[buf] = path
  vim.api.nvim_create_autocmd ("BufWritePost", {
    group = group,
    buffer = buf,
    callback = function () load_and_run (path) end,
  })
  vim.notify ("🔥 Now hot-reloading: " .. path, vim.log.levels.INFO)
end

local function disable_reload (buf)
  hot_buffers[buf] = nil
  vim.api.nvim_clear_autocmds ({ group = group, buffer = buf })
  vim.notify ("🛑 Stopped hot-reloading buffer " .. buf, vim.log.levels.INFO)
end

local function pick_buffer (prompt, buf_map, on_choice)
  local items = {}
  for buf, path in pairs (buf_map) do
    table.insert (items, { label = "[" .. buf .. "] " .. path, buf = buf })
  end
  if #items == 0 then
    vim.notify ("🤷 No matching buffers", vim.log.levels.WARN)
    return
  end
  vim.ui.select (items, {
    prompt = prompt,
    format_item = function (item) return item.label end,
  }, function (choice)
    if choice then on_choice (choice.buf) end
  end)
end

function main.setup ()
  vim.api.nvim_create_user_command ("HotReload", function (opts)
    local subcmd = opts.fargs[1]

    if subcmd == "add" then
      -- Select from ALL LISTED BUFFERS
      local all_bufs = {}
      for _, buf in ipairs (vim.api.nvim_list_bufs ()) do
        local path = vim.api.nvim_buf_get_name (buf)
        if path and path ~= "" then all_bufs[buf] = path end
      end
      pick_buffer ("Select buffer to hot-reload:", all_bufs, enable_reload)
    elseif subcmd == "quit" then
      -- Select from ACTIVE HOT BUFFERS
      pick_buffer ("Select hot-reload buffer to stop:", hot_buffers, disable_reload)
    elseif subcmd == "jump" then
      -- Jump to a buffer
      pick_buffer (
        "Jump to hot-reload buffer:",
        hot_buffers,
        function (buf) vim.api.nvim_set_current_buf (buf) end
      )
    elseif subcmd == "list" then
      if vim.tbl_isempty (hot_buffers) then
        vim.notify ("🤷 No hot-reloading buffers", vim.log.levels.INFO)
        return
      end
      vim.notify (
        "🔥 Hot-reloading:\n"
        .. table.concat (
          tbl.map (hot_buffers, function (k, v) return "[" .. k .. "] " .. v end),
          "\n"
        ),
        vim.log.levels.INFO,
        {}
      )
    elseif subcmd == "quit-all" then
      for buf, _ in pairs (hot_buffers) do
        vim.api.nvim_clear_autocmds ({ group = group, buffer = buf })
      end
      hot_buffers = {}
      vim.notify ("🧹 Cleared all hot-reloads!", vim.log.levels.INFO)
    else
      vim.notify ("❗ Usage: HotReload <add|quit|jump|list|quit-all>", vim.log.levels.ERROR)
    end
  end, {
    nargs = 1,
    complete = function () return { "add", "quit", "jump", "list", "quit-all" } end,
  })
end

return main
