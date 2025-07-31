local str = require ("warm.str")
local tbl = require ("warm.table")

local main = {}

main.toggles = {
  names = {},
  callbacks = {},
  states = {},
}

-- Add a new toggle
--- @param name string The name of the toggle
--- @param callback fun(boolean) The function to call when toggling
--- @param state? boolean Initial state (default: true)
function main.add (name, callback, state)
  state = state == nil and true or state

  local exists, idx = tbl.contains (main.toggles.names, name)
  if exists then
    -- Update existing toggle
    main.toggles.callbacks[idx] = callback
    main.toggles.states[idx] = state
    return
  end

  -- Add new toggle
  table.insert (main.toggles.names, name)
  table.insert (main.toggles.callbacks, callback)
  table.insert (main.toggles.states, state)

  callback (state)
end

-- Toggle a specific toggle by name
--- @param name string The name of the toggle to switch
function main.toggle (name)
  local exists, idx = tbl.contains (main.toggles.names, name)
  local dname = name:gsub ("-", " "):gsub ("^.", string.upper)
  if not exists then
    vim.notify ("Toggle '" .. name .. "' not found", vim.log.levels.WARN, { title = "Toggle" })
    return
  end

  -- Flip the state
  main.toggles.states[idx] = not main.toggles.states[idx]

  -- Call the callback with the new state
  local success, err = pcall (main.toggles.callbacks[idx], main.toggles.states[idx])
  if not success then
    vim.notify (
      "Error in toggle callback for " .. dname .. ": " .. tostring (err),
      vim.log.levels.ERROR,
      { title = "Toggle" }
    )
  else
    local state_str = main.toggles.states[idx] and "enabled" or "disabled"
    vim.notify (
      "Toggle " .. dname .. " " .. state_str,
      vim.log.levels.INFO,
      { title = "Toggle" }
    )
  end

  return main.toggles.states[idx]
end

-- Get the current state of a toggle
--- @param name string The name of the toggle
--- @return boolean? The current state, or nil if toggle doesn't exist
function main.get_state (name)
  local exists, idx = tbl.contains (main.toggles.names, name)
  if not exists then return nil end
  return main.toggles.states[idx]
end

-- List all toggles with their current states
function main.list ()
  local result = {}
  for i, name in ipairs (main.toggles.names) do
    local state = main.toggles.states[i] and "enabled" or "disabled"
    table.insert (result, name .. ": " .. state)
  end
  return result
end

-- Create the user command
vim.api.nvim_create_user_command ("NvstpToggle", function (opts)
  local notify_params = { title = "Nvstp Toggle" }
  local arg1 = opts.fargs[1]

  if arg1 == "--list" or arg1 == "-l" then
    local toggles = main.list ()
    if #toggles == 0 then
      vim.notify ("No toggles defined", vim.log.levels.INFO, notify_params)
      return
    end

    vim.notify ("Available toggles:", vim.log.levels.INFO, notify_params)
    for _, toggle_info in ipairs (toggles) do
      vim.notify ("  " .. toggle_info, vim.log.levels.INFO, notify_params)
    end
    return
  end

  -- Handle toggle
  if not arg1 or arg1 == "" then
    vim.notify (
      "No toggle specified. Use --list to see available toggles.",
      vim.log.levels.WARN,
      notify_params
    )
    return
  end

  main.toggle (arg1)
end, {
  desc = "Toggle features on or off",
  nargs = "?",
  complete = function (arglead, _, _)
    local cmp = vim.tbl_extend ("force", { "--list", "-l" }, main.toggles.names)
    if arglead == "" or str.starts_with (arglead, " ") then return cmp end

    cmp = tbl.filter (cmp, function (_, v) return str.starts_with (v, arglead) end, false)
    if #tbl.get_keys (cmp) == 0 then return main.toggles.names end
    return cmp
  end,
})

return main
