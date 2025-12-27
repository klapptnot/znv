-- String manipulation utils

local spr = require ("warm.spr")
local utf8 = require ("warm.utf8")
local main = {}

--- Remove trailing and leading spaces/linebreaks
--- @param s string
--- @return string
function main.strip (s, ch)
  local stp = "^[\n|%s]*(.-)[\n|%s]*$"
  if ch ~= nil then stp = main.format ("^{1}(.-){1}$", main.pesc (ch)) end
  return (string.gsub (s, stp, "%1"))
end

--- Return the first space separated string (first word)
--- @param s string
--- @return string
function main.pre_string (s) return string.match (s, "[^%s]+") end

--- Return the last space separated string (last word)
--- @param s string
--- @return string
function main.sub_string (s) return string.match (s, "[^%s]+$") end

--- @param s string
--- @param substr string
--- @return boolean
function main.starts_with (s, substr)
  spr.validate ({ "string", "string" }, { s, substr })
  return s:sub (1, #substr) == substr
end

--- @param s string
--- @param ending string
--- @return boolean
function main.ends_with (s, ending)
  spr.validate ({ "string", "string" }, { s, ending })
  return ending == "" or s:sub (- #ending) == ending
end

--- Escape lua magic characters, making a pattern match themselves
-- ```lua
-- local s, r = "This is concat operator: `..`", nil
-- r = string.match(s, str.pesc('..'))) -- r == ".."
-- r = (string.match(s, '..') -- r == "Th"
-- ```
--- @param p string
--- @return string
function main.pesc (p)
  local s, _ = p:gsub ("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%1")
  --  :gsub("(%[acdlpsuwxzACDLPSUWXZ])", "%%%1")
  return s
end

--- Performs a fuzzy match on the given string.
--- @param str string The string to search in
--- @param pattern string The pattern to match against
--- @return boolean matched
--- @return integer[] positions Matched characters
function main.fuzzy (str, pattern)
  pattern = pattern:lower ()
  str = str:lower ()
  local pos = {}
  --- @type integer?
  local j = 1
  for i = 1, #pattern do
    j = str:find (pattern:sub (i, i), j, true)
    if j == nil then return false, pos end
    pos[#pos+1] = j
    j = j + 1
  end
  return true, pos
end

--- Return str if is not nil or zero length, otherwise returns fallback
--- @param s any
--- @param fallback string
--- @return string
function main.fallback (s, fallback)
  if (type (s) == "string" and #s > 0) then return s end
  return fallback
end

--- Return the first non-zero length item or returns fallback
--- @param fallback string
--- @param ... string
--- @return string
function main.first_not_empty (fallback, ...)
  local all = { ... }
  for _, str in ipairs (all) do
    local cond = (type (str) == "string" and #str > 0)
    if cond then return str end
  end
  return fallback
end

--- String as false/string (String is always true)
--- Returns false if string is empty
--- Returns string if string is not empty
--- @param s string|nil
--- @return boolean|string
function main.boolean (s)
  spr.validate ({ { "string?" } }, { s })
  if s ~= nil and #s > 0 then return s end
  return false
end

--- Split a string into a list of strings
--- By default, split by spaces
--- @param s string
--- @param sep? string
--- @return string[]
function main.split (s, sep)
  assert (type (s) == "string", "argument #1 to 'split' must be a string")
  if sep == nil then sep = " " end
  assert (type (sep) == "string", "argument #2 to 'split' must be a string")
  local items = {}
  for item in string.gmatch (s .. sep, "(.-)" .. sep) do
    table.insert (items, item)
  end
  return items
end

--- Split to characters
--- @param s string
--- @return table
function main.chars (s)
  assert (type (s) == "string", "argument #2 to 'split' must be a string")
  local chars = {}
  if #s == 0 then return chars end
  for i = 1, #s do
    table.insert (chars, string.sub (s, i, i))
  end
  return chars
end

-- Simple check if string contains certain substring inside
-- Patterns are matched as plain string
-- ```lua
-- local valid_types = "string,number"
-- assert(valid_types:has(type(v)), 'argument #1 must be either string or number')
-- ```
--- @param s string
--- @param str string
--- @return boolean
function main.has (s, str)
  if #s == 0 or #str == 0 then return false end
  return string.find (s, str, 1, true) ~= nil
end

--- Add padding to s to be n length, default pad right
--- @param s string
--- @param n integer
--- @param fill string|number
--- @param algn "<"|"^"|">"
--- @return string
function main.pad (s, n, fill, algn)
  s = main.fallback (s, "")
  n = tonumber (n) - 0
  local l = utf8.len (s)
  if l >= n then return s end
  algn = main.fallback (algn, "<")
  fill = main.fallback (tostring (fill), " ")
  fill = fill:rep (n):sub (1, n - l)

  if algn == "<" then
    s = s .. fill
  elseif algn == ">" then
    s = fill .. s
  elseif algn == "^" then
    local lfill = string.sub (fill, 1, math.ceil (#fill / 2))
    local rfill = string.sub (fill, 1, math.floor (#fill / 2))
    s = lfill .. s .. rfill
  end
  return s
end

--- String format using brackets instead of C style placeholders
--
-- ```lua
-- str.format("{} version {}.", "soil", 1.0) -- "soil version 1.0"
-- str.format("From: {:<8}| At: {:>8}|", "source", "path") -- "From: source  | At:     path|"
-- str.format("Var: {:_^20}.", "APP_VERSION") -- "Var: _____APP_VERSION____."
-- str.format("Grab: {:10}.", "none") -- "Grab:       none."
-- str.format("[3: {3}, 1: {}, 4: {4}, 2: {}]", "one", "two", "three", "four") -- [3: three, 1: one, 4: four, 2: two]
-- ```
--- @param s string
--- @param ... any
--- @return string
function main.format (s, ...)
  local args = { ... }
  local i = 1

  local function index_in (ign)
    if ign == "\\" then return "{}" end
    i = i + 1
    return args[i - 1]
  end

  local function replacement (ign, id, match)
    if ign == "\\" then return "{" .. id .. match .. "}" end
    id = tonumber (id)
    if id == nil then
      id = i
      i = i + 1
    end

    if match == "" then return args[id] end
    local width = tonumber (match:match ("(%d+)$")) or 0 -- Width
    local pad = match:match ("([<^>]?)%d+$") or "<" -- Pad opr
    local cut = match:match (":.?(=)[<^>]?%d+$") ~= nil -- Cut longer
    local char = match:match (":(.?)=?[<^>]%d+$") or " " -- Fill char

    match = tostring (args[id])
    -- In case string is wider than desired, cut it
    local length = utf8.len (match)
    if cut and length > width then
      -- match = utf8.sub (match, 1, width) .. "…"
      if #match == length then -- byte length == char length = pure ASCII
        match = match:sub (1, width - 1) .. "…"
      else
        match = utf8.sub (match, 1, width - 1) .. "…"
      end
    else
      match = main.pad (match, width, char, pad)
    end
    return match
  end

  s = string.gsub (s, "(\\?){(%d*)(:.?=?[=<^>]?%d*)}", replacement)
    :gsub ("(\\?){}", index_in)
  return s
end

return main
