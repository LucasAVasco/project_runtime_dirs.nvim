local Config = require("project_runtime_dirs.config")
local Cache = require("project_runtime_dirs.cache")
local Text = require("project_runtime_dirs.text")
local Check = require("project_runtime_dirs.check")

-- API

local ApiFolder = require("project_runtime_dirs.api.folder")

---API to manage runtime sources of the `project_runtime_dirs.nvim` plugin
---@class (exact) ProjectRtdApiSource
---@field get_list_paths fun(): string[]
---@field path_exists fun(path: string): boolean
---@field get_all_rtd_names fun(): string[]
---@field RuntimeSource RuntimeSource
---@field get_source_by_path fun(path: string): RuntimeSource?
---@field select_source_by_path fun(callback: fun(RuntimeSource?))
local M = {}

---Return the list of runtime source directories
---@return string[]
---@nodiscard
function M.get_list_paths()
    return Config.merged.sources
end

---Return `true` if the runtime source exists. Otherwise, return `false`
---@param path string Absolute path of the runtime source
---@return boolean
---@nodiscard
function M.path_exists(path)
    for _, source_path in pairs(M.get_list_paths()) do
        if source_path == path then
            return true
        end
    end

    return false
end

-- Runtime source class {{{

---Class to manage a runtime source
---@class (exact) RuntimeSource: DirManager
---@field __index? RuntimeSource
M.RuntimeSource = {}
M.RuntimeSource.__index = M.RuntimeSource
setmetatable(M.RuntimeSource, ApiFolder.DirManager)

---Return a list of all the runtime directories of the runtime source
---@param ignore_errors? boolean Does not notify if can not access the runtime source
---@return string[]
---@nodiscard
function M.RuntimeSource:get_rtds(ignore_errors)
    return self:list_files(".", ignore_errors) or {}
end

---Checks if the runtime source has the runtime directory
---@param name string Name of the runtime directory
---@return boolean has_rtd `true` if the runtime source has the runtime directory, `false` otherwise
---@nodiscard
function M.RuntimeSource:has_runtime_dir(name)
    return self:isdirectory(name)
end

---Create a runtime directory
---@param name string Name of the runtime directory
---@param ignore_errors? boolean Does not notify if can not create the runtime directory
function M.RuntimeSource:create_runtime_dir(name, ignore_errors)
    if self:has_runtime_dir(name) then
        if not ignore_errors then
            vim.notify("Error creating the runtime directory. It already exists", vim.log.levels.ERROR)
        end

        return
    end

    if Check.rtd_name_is_valid(name, not ignore_errors) then
        self:mkdir(self.path .. name, "p")
    end
end

---Create a runtime source object by its path
---You need to provide the path of the runtime source directory. This function will check if this path is available in the user
---configuration. If can not find it, returns `nil`. Caches the created runtime source and returns the cached one when available.
---@param path string|number Path of the runtime source. Or index in the list of configured runtime sources
---@return RuntimeSource? new The created (or cached) runtime source, or `nil` if the path is not available in the user configuration
---@nodiscard
function M.RuntimeSource:new(path)
    -- Convert index to path
    if type(path) == "number" then
        path = Config.merged.sources[path]
    end

    -- Does not create a new runtime source object if it already has been created
    for _, src in pairs(Cache.source) do
        if path == src.path then
            return src
        end
    end

    -- Checks if the runtime source exists
    if not M.path_exists(path) then
        vim.notify(("The provided runtime source does not exist. Path: %s"):format(path), vim.log.levels.ERROR)
        return
    end

    ---New runtime source object
    ---@type RuntimeSource
    local new = {
        path = Text.add_trailing_slash(path),
    }

    setmetatable(new, M.RuntimeSource)

    -- Saves the created runtime source object in the cache
    table.insert(Cache.source, new)

    return new
end

-- }}}

---Interactively select a runtime source
---Calls the callback function after the user select the runtime source
---@param callback fun(rts?: RuntimeSource) Function called after the user select the runtime source. Receives the selected one
function M.select_source_by_path(callback)
    vim.ui.select(Config.merged.sources, {
        prompt = "Name of the Project",
    }, function(selected_path, _)
        local rts = nil

        if selected_path then
            rts = M.RuntimeSource:new(selected_path)
        end

        callback(rts)
    end)
end

return M
