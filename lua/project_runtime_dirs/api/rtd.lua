local Config = require("project_runtime_dirs.config")
local Text = require("project_runtime_dirs.text")
local Cache = require("project_runtime_dirs.cache")
local Check = require("project_runtime_dirs.check")
local notification = require("project_runtime_dirs.notification")

-- API

local ApiFolder = require("project_runtime_dirs.api.folder")

---API to manage runtime directories of the `project_runtime_dirs.nvim` plugin
---@class (exact) ProjectRtdApiRtd
---@field RuntimeDir RuntimeDir
local M = {}

-- Runtime directory class {{{

---@class (exact) RuntimeDirLinkedRtd
---@field names string[] names of the inherited named runtime directories
---@field rtds RuntimeDir[] inherited named runtime directories

---Class to manage a runtime directory
---@class (exact) RuntimeDir: DirManager
---@field name string Name of the runtime directory
---@field deps RuntimeDirLinkedRtd Runtime directories that the current one requires
---@field __index? RuntimeDir
M.RuntimeDir = {}
M.RuntimeDir.__index = M.RuntimeDir
setmetatable(M.RuntimeDir, ApiFolder.DirManager)

---Create a runtime directory object.
---You need to provide the name of the runtime directory. This function will search it in the configured source directories and
---automatically set the runtime directory path. If it can not find the runtime directory in any of these source folders, returns `nil`.
---Caches the created runtime directories and returns the cached one when available. There are a maximum number of runtime directories that
---the cache can hold, but this number of high and will rarely limit the runtime directory creation. If the cache is full, does not create
---the runtime directory and returns `nil`.
---@param name string Name of the runtime directory
---@return RuntimeDir? rtd The created (or cached) runtime directory, or `nil` if the function cannot create one
---@nodiscard
function M.RuntimeDir:new(name)
    -- Does not create a runtime directory with invalid name
    if not Check.rtd_name_is_valid(name, true) then
        return
    end

    -- Does not create a new runtime directory object if it already has been created
    for _, rtd in pairs(Cache.rtd) do
        if name == rtd.name then
            return rtd
        end
    end

    -- Max number of runtime directories
    if Cache.rtd_is_full() then
        notification.show(
            ("Max number of runtime directories. Cache is full!. Max: %d"):format(Cache.rtd_max),
            vim.log.levels.ERROR
        )
        return
    end

    ---Path of the new runtime directory
    ---@type string?
    local path = nil

    for _, dir in pairs(Config.merged.sources) do
        local try_path = dir .. name
        if vim.fn.isdirectory(try_path) == 1 then
            path = Text.add_trailing_slash(try_path)
            break
        end
    end

    -- Aborts if can not find the runtime directory
    if path == nil then
        return
    end

    ---New runtime directory object
    ---@type RuntimeDir
    local new = {
        path = path,
        name = name,
        deps = {
            rtds = {},
            names = {},
        },
    }

    setmetatable(new, M.RuntimeDir)

    -- Saves the created runtime directory object in the cache
    table.insert(Cache.rtd, new)
    table.insert(Cache.project.enabled_rtd_names, new.name)

    -- Enables the runtime directory
    vim.opt.rtp:append(new.path)
    if new:filereadable("init.lua") then
        dofile(new:get_abs_path("init.lua"))
    end

    -- File with the names of the inherited runtime directories
    local sub_rtds_file = new:open("runtime-dir-deps")
    if sub_rtds_file then
        for line in sub_rtds_file:lines() do
            ---@cast line string
            line = Text.remove_newlines(line)

            if line ~= "" then
                table.insert(new.deps.names, line)
                table.insert(new.deps.rtds, M.RuntimeDir:new(line))
            end
        end
        sub_rtds_file:close()
    end

    return new
end

-- }}}

return M
