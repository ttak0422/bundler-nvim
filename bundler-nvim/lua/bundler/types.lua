---@class Options
---@field root string
---@field lazy_time number

---@class Bundler
---@field root string
---@field lazy_time number
---@field new fun(opts: Options): Bundler
---@field setup_loader fun(self: Bundler)
---@field configure fun(self: Bundler, id: string, is_pre: boolean)
---@field loaded_plugins { [string]: boolean }
---@field loaded_modules { [string]: boolean }
---@field load_plugin fun(self: Bundler, id: string)
---@field load_plugins fun(self: Bundler, path: string)
