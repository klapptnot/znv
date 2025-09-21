-- Wincker ASCII art font parser and loader
-- !! Supports .flf fonts, commonly figlet fonts

-- `fwd` File Work Directory
local str = require ("warm.str")
local uts = require ("warm.uts")

--- @alias flffont.char { s:string, l:string[], c:string } Font character, [s]tring and [l]lines with [c]har to know which character is

--- @class flffont
--- @field get_char fun(self:flffont, c:string):flffont.char Get a character from this font
--- @field get_string fun(self:flffont, s:string):string Get a string made of this font
--- @field data string[]
--- @field header string[]
--- @field height number
--- @field blank string
--- @field chars flffont.char[]
--- @field [string] flffont.char

local main = {}

--- Load a .flf font
--- @param fontname string
--- @return flffont
function main.load (fontname)
  --- @type string
  local meloc = uts.fwd ()
  if fontname == nil then fontname = "" end
  local fontpath = vim.fs.joinpath (meloc, fontname .. ".flf")
  if not vim.uv.fs_stat (fontpath) then
    fontpath = vim.fs.joinpath (meloc, "ansi-regular.flf")
  end

  --- @type string[]
  local file = {}
  for ln in io.lines (fontpath) do
    file[#file+1] = ln
  end
  -- Get header and data information
  local header_head = str.split (file[1], " ")
  -- header_head[6] is header line count

  local header_end = tonumber (header_head[6])
  header_end = header_end + 1 -- Should be so
  if file[header_end] == "" then header_end = header_end + 1 end

  --- @class flffont
  local font = {}
  font.data = table.move (file, header_end, #file - 1, 1, {})
  font.header = table.move (file, 1, tonumber (header_head[6]) + 0, 1, {})
  font.height = tonumber (header_head[2]) + 0
  font.blank = header_head[1]:sub (-1)
  font.chars = {}

  function font:get_char (c)
    if type (c) ~= "string" then error ("unexpected type for argument #1") end
    c = c:sub (1, 1) -- Ensure #char == 1
    if self.chars[c] ~= nil then return self.chars[c] end
    local cpos = (c:byte () - 32) * self.height
    local cbig = { "", {} }
    for i = 1, self.height do
      -- stylua: ignore
      local ccbig = self.data[cpos + i]
      ccbig = self.data[cpos + i]
        :gsub (".$", "")
        :gsub (self.blank:gsub ("%$", "%%$"), " ")
        :gsub (" ", " ")
      if i == self.height then ccbig = ccbig:gsub (".$", "") end
      cbig[1] = cbig[1] .. ccbig .. "\n" -- Save string
      cbig[2][i] = ccbig -- Save lines
    end
    --- @type flffont.char
    local char = {
      s = cbig[1],
      l = cbig[2],
      c = c,
    }
    self.chars[c] = char
    return char
  end

  function font:get_string (s)
    if s == nil then return "" end
    assert (type (s) == "string" and #s > 0, "argument #1 must be a non-zero lenght string")
    local bs = {}
    for i = 1, #s do
      local ct = self:get_char (s:sub (i, i + 1)).l
      for j, l in ipairs (ct) do
        if bs[j] == nil then bs[j] = "" end
        bs[j] = bs[j] .. l
      end
    end
    return table.concat (bs, "\n")
  end

  setmetatable (font, {
    __index = function (t, k)
      if type (k) == "string" then
        if #k == 1 then return t:get_char (k) end
        return t[k]
      end
    end,
  })
  return font
end

return main
