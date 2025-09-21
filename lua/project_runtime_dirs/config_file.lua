local check = require("project_runtime_dirs.check")

local M = {}

---Create a new empty configuration file
---@return ProjectRtdTypesProjectFile
function M.new()
    ---@type ProjectRtdTypesProjectFile
    return {
        runtime_dirs = {},
    }
end

---Parse a configuration file.
---@param path string Path of the configuration file.
---@return ProjectRtdTypesProjectFile? config, string? error Loaded configurations or `nil` if there is an error
function M.parse(path)
    -- Project configuration file
    local content_text = vim.secure.read(path)
    if not content_text then
        return nil, "Error reading configuration file"
    end

    -- If it is a directory
    if content_text == true then
        return nil, "Configuration file is a directory"
    end

    ---Project file converted to Lua Table
    ---@type ProjectRtdTypesProjectFile
    local project_file_json = vim.json.decode(content_text)
    if not check.project_file_is_valid(project_file_json, true) then
        return nil, "Invalid configuration file"
    end

    -- New configuration file
    local config = M.new()
    config.runtime_dirs = project_file_json.runtime_dirs or {}

    -- Updates the cache
    -- cache.project.configured_rtd_names = project_file_json.runtime_dirs or {}
    return project_file_json
end

---Save a configuration file
---@param path string Path to save the configuration file
---@param content ProjectRtdTypesProjectFile Content of the configuration file
function M.save(path, content)
    -- Project configuration file
    local json_string = vim.json.encode(content)
    vim.fn.writefile({ json_string }, path)
    vim.secure.read(path) -- Asks the user to confirm tht the file is secure
end

return M
