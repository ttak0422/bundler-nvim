---@class Logger
local log = require("bundler.log")
log.new({
	plugin = "bundler-nvim",
	level = "info",
}, true)

--- utils.
local au = vim.api.nvim_create_autocmd
local packadd = function(path)
	local p = dofile(path)
	if p ~= nil then
		log.debug("[packadd]", p)
		vim.cmd("packadd " .. p)
	end
end

---@class Bundler
local M = {}

M.loaded_plugins = {}

M.loaded_modules = {}

--- constructor.
M.new = function(opts)
	local self = setmetatable({}, { __index = M })
	self.root = opts.root
	self.lazy_time = opts.lazy_time
	return self
end

M.setup_loader = function(self)
	log.debug("[setup_loader] start", self.root)
	dofile(self.root .. "/startup")

	for _, ev in ipairs(dofile(self.root .. "/event_keys")) do
		log.debug("ev:", ev)
		au({ ev }, {
			pattern = "*",
			once = true,
			callback = function()
				self:load_plugins(self.root .. "/events/" .. ev)
			end,
		})
	end
	for _, ft in ipairs(dofile(self.root .. "/filetype_keys")) do
		log.debug("ft:", ft)
		au({ "FileType" }, {
			pattern = ft,
			once = true,
			callback = function()
				self:load_plugins(self.root .. "/filetypes/" .. ft)
			end,
		})
	end
	for _, cmd in ipairs(dofile(self.root .. "/command_keys")) do
		log.debug("cmd:", cmd)
		au({ "CmdUndefined" }, {
			pattern = cmd,
			once = true,
			callback = function()
				self:load_plugins(self.root .. "/commands/" .. cmd)
			end,
		})
	end
	table.insert(package.loaders, 1, function(mod_name)
		if not self.loaded_modules[mod_name] then
			self.loaded_modules[mod_name] = true

			local ok, ids = pcall(dofile, self.root .. "/modules/" .. mod_name)
			if ok then
				for _, id in ipairs(ids) do
					self:load_plugin(id)
				end
			end
		end
	end)
	vim.defer_fn(function()
		self:load_plugins(self.root .. "/lazys")
	end, self.lazy_time)
	log.debug("[setup_loader] end")
end

M.configure = function(self, id, is_pre)
	log.debug(is_pre and "[pre_config]" or "[config]", "start", id)
	local dir = is_pre and "/pre_config/" or "/config/"
	local ok, err_msg = pcall(dofile, self.root .. dir .. id)
	if not ok then
		log.error(id, " configure error: ", err_msg or "-- no msg --")
	end
	log.debug(is_pre and "[pre_config]" or "[config]", "end", id)
end

M.load_plugin = function(self, id)
	if not self.loaded_plugins[id] then
		log.debug("[load_plugin] start", id)
		self.loaded_plugins[id] = true
		self:configure(id, true)
		self:load_plugins(self.root .. "/depends/" .. id)
		self:load_plugins(self.root .. "/depend_bundles/" .. id)
		self:load_plugins(self.root .. "/plugins/" .. id)
		packadd(self.root .. "/plugin/" .. id)
		self:configure(id, false)
		log.debug("[load_plugin] end", id)
	end
end

M.load_plugins = function(self, path)
	for _, p in ipairs(dofile(path)) do
		self:load_plugin(p)
	end
end

return M
