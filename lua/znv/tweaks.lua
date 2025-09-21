local main = {}

main.tweaks = {
  detect_indent = function ()
    local function guess_set_indent ()
      local a, b, c = vim.bo.shiftwidth, vim.bo.tabstop, vim.bo.softtabstop
      local width = require ("warm.indent").guess ()
      if width == nil then return end
      vim.bo.shiftwidth = width
      vim.bo.tabstop = width
      vim.bo.softtabstop = width

      if a == width then return end
      vim.notify (
        string.format ("Indentation size changed, from %d:%d:%d to %d", a, b, c, width),
        vim.log.levels.INFO,
        { title = "Tweaks" }
      )
    end

    -- Set indentation based on guesses, works better btw
    vim.api.nvim_create_user_command ("ZnvIndentSet", function (opts)
      local width = tonumber (opts.fargs[1])
      assert (width ~= nil, "number is nil")
      assert (width % 2 == 0, "number is not a even number")
      if vim.bo.shiftwidth == width then return end

      print (
        string.format (
          "Indentation size changed, from %d:%d:%d to %d",
          vim.bo.shiftwidth,
          vim.bo.tabstop,
          vim.bo.softtabstop,
          width
        )
      )

      vim.bo.shiftwidth = width
      vim.bo.tabstop = width
      vim.bo.softtabstop = width
    end, { desc = "Guess and set indent level [def: 2]", nargs = "+" })
    vim.api.nvim_create_autocmd ({ "BufReadPost" }, {
      pattern = "*",
      callback = guess_set_indent,
    })
  end,
  reset_cursor = function ()
    -- Reset cursor style on exit
    vim.api.nvim_create_autocmd ({ "VimLeave" }, {
      pattern = { "*" },
      command = 'set guicursor= | call chansend(v:stderr, "\\x1b[ q")',
    })
  end,

  lua_functions = function ()
    -- !! Neovim has Lua 5.1, so make it appear Lua 5.4
    -- !! moving unpack to table.unpack
    -- !! making forward compatibility easy (When available, remove this)
    table.unpack = unpack

    --- Returns a new table with all arguments stored into keys `1`, `2`, etc. and with a field `"n"` with the total number of arguments.
    ---
    --- [View documents](http://www.lua.org/manual/5.4/manual.html#pdf-table.pack)
    ---
    --- @return table
    --- @nodiscard
    table.pack = table.pack
      or function (...)
        local t = { ... }
        rawset (t, "n", #t)
        return t
      end

    -- Simple check if string contains other string inside
    -- Patterns are matched as plain string
    -- ```lua
    -- local valid_types = "string,number"
    -- assert(valid_types:has(type(v)), 'argument #1 must be either string or number')
    -- ```
    --- @param s string|number
    --- @param str string|number
    --- @return boolean
    string.has = function (s, str)
      if #s == 0 or #str == 0 then return false end
      return string.find (s, str, 1, true) ~= nil
    end

    --- Print string to `stdout`.
    --- Same as print(string), but avoiding weird editing
    -- ```lua
    -- local fmt = '%d.%d.%d'
    -- fmt:format(major, minor, patch):print()
    -- ```
    --- @param s string
    string.print = function (s) print (s) end

    --- Write string to default output file (mainly `stdout`).
    --- Used to `print()` without trailing `\n`
    -- ```lua
    -- local fmt = '%d.%d.%d'
    -- fmt:format(major, minor, patch):put()
    -- ```
    --- @param s string
    string.put = function (s) io.write (s) end
  end,
}

function main.apply ()
  for n, v in pairs (ZNV.tweaks) do
    if v == true and main.tweaks[n] ~= nil then main.tweaks[n] () end
  end
end

return main
