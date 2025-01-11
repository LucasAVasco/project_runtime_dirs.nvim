local Config = require("project_runtime_dirs.config")
local Cache = require("project_runtime_dirs.cache")

---Functions to manage loaded runtime directories
---@class (exact) ProjectRtdApiProjectEnabledRtds
---@field get_all_names fun(): string[]
---@field get_all fun(): RuntimeDir[]
---@field get_by_name fun(name: string): RuntimeDir?
---@field select_by_name fun(callback: fun(rtd: RuntimeDir))
local M = {}

---Get the names of all created runtime directories
---@return string[]
---@nodiscard
function M.get_all_names()
    return Cache.project.enabled_rtd_names
end

---Get all created runtime directories
---@return RuntimeDir[]
---@nodiscard
function M.get_all()
    return Config.done.rtds
end

---Get a runtime directory by its name
---@param name string Name of the runtime directory
---@return RuntimeDir?
---@nodiscard
function M.get_by_name(name)
    for _, rtd in pairs(Config.done.rtds) do
        if rtd.name == name then
            return rtd
        end
    end
end

---Interactively select a runtime directory
---@param callback fun(rtd: RuntimeDir?) Function called after the user select the runtime directory. Receives the selected one
function M.select_by_name(callback)
    vim.ui.select(M.get_all_names(), {
        prompt = "Select a runtime directory:",
    }, function(_, index)
        local rtd = nil
        if index then
            rtd = Config.done.rtds[index]
        end

        callback(rtd)
    end)
end

return M
