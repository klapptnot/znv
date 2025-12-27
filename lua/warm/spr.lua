-- functional API

local main = {}

-- back-compat
if table.unpack == nil then
  --- @diagnostic disable-next-line: deprecated
  table.unpack = unpack
end

function main.range (i, j)
  main.validate ({ "number", "number" }, { i, j })
  local function rnext (n) return n + 1 end
  local function in_range (n) return (n >= i and n <= j) end

  if i > j then
    function rnext (n) return n - 1 end

    function in_range (n) return (n >= j and n <= i) end
  end

  local len = math.abs (i - j) + 1
  if j < 0 and i < 0 then
    len = math.abs (i - j) + 1
  elseif j < 0 or i < 0 then
    len = math.abs (i + j) + 5
  end

  local function iterator ()
    local l = i - 1
    if i > j then l = i + 1 end
    return function ()
      l = rnext (l)
      if not in_range (l) then return nil end
      return l
    end
  end

  return setmetatable ({ match = in_range, iter = iterator }, {
    __mod = function (_, n) return in_range (n) end,
    __len = function (_) return len end,
    __pairs = iterator,
  })
end

--- Wrap functions. Bind some arguments to constant ones like functional programming
--- @param fn fun(...)
--- @param ... any
--- @return fun(...)
function main.funwrap (fn, ...)
  assert (type (fn) == "function", "argument #1 to 'funwrap' must be a function")
  local perm_args = { ... }
  return function (...)
    return fn (table.unpack (perm_args), ...)
  end
end

--- Safely require/load a file/module and set a fallback (default: nil)
--- @generic T
--- @param module string
--- @param fallback? T
--- @return T|unknown
function main.safe_require (module, fallback)
  local success, mod = pcall (require, module)
  if success then return mod end
  return fallback
end

--- Lazy require a module item (require when item is used)
--- @param require_path string
--- @return table
function main.lazy_require (require_path)
  return setmetatable ({}, {
    __call = function (_, ...) return require (require_path) (...) end,
    __index = function (_, key) return require (require_path)[key] end,
  })
end

--- Iniitialize a iterator with args and collect all items into a list
--- @param iter fun(...)
--- @param ... any
--- @return table
function main.collect (iter, ...)
  local its = {}
  local _, b = iter (...)
  if b == nil then
    for v in iter (...) do
      its[#its+1] = v
    end
  else
    for _, v in iter (...) do
      its[#its+1] = v
    end
  end
  return its
end

--- Match it with keys of rules
--
-- Returns a function that checks for a match in keys of its
--
-- arg, and returns the value or return value of the function (if it's one and call is true)
--- @generic V
--- @param it string|integer
--- @param call? boolean
--- @return fun(with:table<string|integer, some|fun():V>):V
function main.match (it, call)
  if call == true then
    return function (with)
      if with == nil or with[it] == nil then
        if type (with._def) == "function" then return with._def () end
        return with._def
      end

      local item = with[it]
      if type (item) == "function" then return item () end
      return item
    end
  else
    return function (with)
      if with == nil or with[it] == nil then return with._def end
      local item = with[it]
      return item
    end
  end
end

--- Switch your code flow, returns matching value or `_` value
--- @generic V
--- @param any any
--- @param call? boolean
--- @return fun(with:table<any, V|fun():V>[]):V
function main.switch (any, call)
  if call == true then
    return function (with)
      if with == nil then return nil end
      for _, v in pairs (with) do
        if any == v[1] then
          if type (v[2]) == "function" then return v[2] () end
          return v[2]
        end
      end
      if type (with._def) == "function" then return with._def () end
      return with._def
    end
  else
    return function (with)
      if with == nil then return nil end
      for _, v in pairs (with) do
        if any == v[1] then return v[2] end
      end
      return with._def
    end
  end
end

--- Returns the passed arguments in reversed order
--- @generic items
--- @param ...items
--- @return ...
function main.invert (...)
  local args = { ... }
  local reversed = {}
  for i = #args, 1, -1 do
    table.insert (reversed, args[i])
  end
  return table.unpack (reversed)
end

--- Return the results of a protected call or a fallback value
--- @param f any
--- @param ... any
--- @return ...
--- @nodiscard
function main.fcall (f, ...)
  local res = { pcall (...) }
  local ok, rv = res[1], table.move (res, 2, #res, 1, {})

  if ok then return table.unpack (rv) end
  if type (f) == "function" then return f (rv, ...) end

  return f
end

--- Return a callable table to manage errors and multiruns
--- @generic T
--- @param fn fun(T):unknown
--- @param ... T
--- @return table
--- @nodiscard
function main.rcall (fn, ...)
  local self = {
    args = { ... },
    fn = fn,
  }
  setmetatable (self, {
    __call = function ()
      if #self.args == 0 then
        local res = { pcall (fn) }
        self.ok, self.rv = res[1], table.move (res, 2, #res, 1, {})
      else
        local res = { pcall (fn, table.unpack (self.args)) }
        self.ok, self.rv = res[1], table.move (res, 2, #res, 1, {})
      end

      -- Return the result value of the function
      --
      -- Returns as a list if `unpck` ~= `true`
      --- @param unpck boolean?
      --- @return ...
      function self.unwrap (unpck)
        if unpck == true then return table.unpack (self.rv) end
        return self.rv
      end

      -- Return the result value of the function, or a fallback value
      --
      -- Returns as a list if `unpck` ~= `true`
      --
      -- If `f` is a function it's called with the results and return value will be returned
      --- @generic F
      --- @param f F|fun(rv:any[]):F
      --- @param unpck boolean
      --- @return F?
      function self.unwrap_or (f, unpck)
        if self.ok then
          return self.unwrap (unpck)
        elseif type (f) == "function" then
          return f (self.rv)
        else
          return f
        end
      end

      return self.ok
    end,
  })
  return self
end

--- Validate the arguments passed to it based on the given rules
--- @param t ListScheme
--- @param args any[]
function main.validate (t, args)
  --- @param s string
  --- @param f string
  --- @return string
  local function str_fallback (s, f)
    local cond = (s ~= nil and #s > 0 and type (s) == "string")
    if cond then return s end
    return f
  end

  local concat_sep = str_fallback (t.sep, ", ")
  local type_err_msg =
    str_fallback (t.type_err, "bad argument #%d (expected one of [%s], got [%s])")
  local value_err_msg =
    str_fallback (t.value_err, "bad argument #%d (expected value from [%s], got [%s]")

  for i, arg_rule in ipairs (t) do
    local expected_types
    if type (arg_rule) == "table" then
      expected_types = arg_rule
    else
      expected_types = { arg_rule }
    end
    local expected_values = arg_rule.from
    local arg = args[i]
    -- Check if the argument matches any of the expected types
    local type_err = true
    local try_nil = false
    local arg_type = type (arg)
    for _, expected_type in ipairs (expected_types) do
      -- "some" is "Any value but nil"
      --- @cast expected_type string
      if expected_type:sub (-1) == "?" then
        expected_type = expected_type:sub (1, -2)
        try_nil = true
      end
      if arg_type == "nil" then
        if expected_type == "some" then break end
        if try_nil then type_err = false end
      end
      if arg_type == expected_type or expected_type == "some" then
        type_err = false
        break
      end
    end
    if type_err then
      error (
        str_fallback (arg_rule.type_err, type_err_msg):format (
          i,
          table.concat (expected_types, concat_sep),
          arg_type
        )
      )
    end
    -- Check if the argument is within the expected values
    if expected_values then
      local is_valid_value = false
      for _, value in ipairs (expected_values) do
        if arg == value then
          is_valid_value = true
          break
        end
      end
      if not is_valid_value then
        error (
          str_fallback (arg_rule.type_err, value_err_msg):format (
            i,
            table.concat (expected_values, concat_sep),
            tostring (arg)
          )
        )
      end
    end
  end
end

--- Validate and parse a string
--- @generic T
--- @param t ArgParseScheme
--- @param args T
--- @return T
--- @nodiscard
function main.parse_args (t, args)
  main.validate (t, args)
  local parsed_args = {}
  for i, arg_rule in ipairs (t) do
    local arg = args[i]
    if arg == nil then
      parsed_args[i] = arg_rule.def
    else
      parsed_args[i] = arg
    end
  end
  return parsed_args
end

--- Evaluate the truthiness of a value, according to js/python rules.
--- @param val any
--- @return boolean
function main.truthy (val)
  if val == nil then return false end
  -- stylua: ignore
  return main.match (type (val)) {
    boolean = val,
    string = val > "",
    number = val > 0,
    table = #main.collect (pairs, val) > 0,
    _def = true,
  }
end

return main
