local builtins = {
  whichkey = "src.znv.palette.builtin.whichkey",
  lsp_symbols = "src.znv.palette.builtin.lsp_symbols",
  -- git = "src.znv.palette.builtin.git",
}

--- @type table<string, fun(...)>
local PaletteLoader = {}

setmetatable (PaletteLoader, {
  __index = function (self, key)
    local modname = builtins[key]
    if not modname then
      vim.notify (
        "Palette picker '" .. key .. "' not registered in builtins",
        vim.log.levels.WARN
      )
      return function () end
    end

    local ok, mod = pcall (require, modname)
    if not ok then
      vim.notify (
        "Failed to load picker '" .. key .. "' from '" .. modname .. "': " .. mod,
        vim.log.levels.ERROR
      )
      return function () end
    end

    self[key] = mod
    return mod
  end,
})

return PaletteLoader
