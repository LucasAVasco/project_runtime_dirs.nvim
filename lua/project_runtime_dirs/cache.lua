---@class (exact) ProjectRtdCacheProject
---@field all_rtd_names? string[] Names of all runtime directories including the not enabled ones
---@field enabled_rtd_names string[] Names of all enabled runtime directories
---@field configured_rtd_names? string[] Names of all runtime directories configured to the current project

---Module to manage  the cached variables of the `project_runtime_dirs.nvim` plugin
---@class (exact) ProjectRtdCache
---@field rtd RuntimeDir[] Cache of created runtime directories
---@field rtd_names RuntimeDir[] Cache with the name of created runtime directories
---@field rtd_max number Max number of runtime directories to create
---@field source RuntimeSource[] Cache of source directories
---@field project ProjectRtdCacheProject Cache to the current project
---@field rtd_is_full fun(): boolean
local M = {
    rtd = {},
    rtd_max = 500,
    source = {},
    project = {
        enabled_rtd_names = {},
    },
}

---Return `true` if the cache is full (you can not add more runtime directories)
---@return boolean
function M.rtd_is_full()
    return #M.rtd >= M.rtd_max
end

return M
