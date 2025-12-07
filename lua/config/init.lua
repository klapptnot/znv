-- config loader

--- @alias ZnvConfig {mapping:NvimMappingConfig; plugins:NvimPluginsConfig}

-- Just load options
require ("config.options")

--- @type ZnvConfig
local main = {
  --- @return NvimMappingConfig
  mapping = require ("config.mapping"):new (),
  --- @return NvimPluginsConfig
  plugins = require ("config.plugins"):new (),
} -- Return all configs classes

return main
