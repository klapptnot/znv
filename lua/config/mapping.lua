local __map__ = require ("config.data.mapping")

--- @class NvimMappingConfig
local main = {}

--- Return a new instance of mapping table
--- @param tbl? ZnvKeyMap[]
--- @return NvimMappingConfig
function main:new (tbl)
  --- @type ZnvKeyMap[]
  self = tbl or __map__
  setmetatable (self, { __index = main })
  return self
end

--- Merge mappings table into self
--- @param tbl table
--- @return NvimMappingConfig
function main:merge (tbl) return self:new (vim.tbl_deep_extend ("force", self, tbl)) end

--- Apply all `mapps` in the most common modes
--- @param mapps {[1]:string, [2]:string}[]
--- @return NvimMappingConfig
function main:map (mapps)
  if mapps == nil then return self end
  --- @type vim.api.keyset.keymap
  local opts = { noremap = true, silent = true }
  for _, mapp in ipairs (mapps) do
    vim.api.nvim_set_keymap ("n", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("v", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("i", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("t", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("x", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("s", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("o", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("c", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("!", mapp[1], mapp[2], opts)
    vim.api.nvim_set_keymap ("l", mapp[1], mapp[2], opts)
  end
  return self
end

--- Disable the mouse mappings
--- @return NvimMappingConfig
function main:disable_mouse ()
  local mouse_events = {
    { "<LeftMouse>",        "<nop>" },
    { "<LeftDrag>",         "<nop>" },
    { "<LeftRelease>",      "<nop>" },
    { "<RightMouse>",       "<nop>" },
    { "<RightDrag>",        "<nop>" },
    { "<RightRelease>",     "<nop>" },
    { "<MiddleMouse>",      "<nop>" },
    { "<MiddleDrag>",       "<nop>" },
    { "<MiddleRelease>",    "<nop>" },
    { "<ScrollWheelUp>",    "<nop>" },
    { "<ScrollWheelDown>",  "<nop>" },
    { "<ScrollWheelLeft>",  "<nop>" },
    { "<ScrollWheelRight>", "<nop>" },
  }
  self:map (mouse_events)
  return self
end

--- Add one keybinding to the table
--- @param props ZnvKeyMap
--- @return NvimMappingConfig
function main:add (props)
  self[#self+1] = props
  return self
end

--- Apply all mappings to nvim
function main:apply ()
  local rcall = require ("warm.spr").rcall
  local fmt = string.format

  for _, props in pairs (self) do
    --- @cast props ZnvKeyMap
    if type (props.exec) == "function" then
      --- @diagnostic disable-next-line: assign-type-mismatch
      props.opts.callback = props.exec
      props.exec = ""
    end
    props.opts = props.opts or {}
    props.opts.desc = props.desc -- Just to not nest items
    for _, mode in ipairs (props.mode) do
      local map_key = rcall (vim.api.nvim_set_keymap, mode, props.mapp, props.exec, props.opts)
      if not map_key () then
        print (fmt ("Mapping error for '%s': %s", tostring (props.desc), map_key.unwrap (true)))
      end
    end
  end
  return self
end

return main
