---@module "project_runtime_dirs.types.rtd"

local Config = require("project_runtime_dirs.config")
local Cache = require("project_runtime_dirs.cache")
local Check = require("project_runtime_dirs.check")
local Text = require("project_runtime_dirs.text")
local ApiRtd = require("project_runtime_dirs.api.rtd")

-- API

---API to manage the current project of the `project_runtime_dirs.nvim` plugin and its runtime directories
---@class (exact) ProjectRtdApiProject
---@field get_project_directory fun(): string?
---@field get_project_configuration_directory fun(): string?
---@field read_project_file fun(): ProjectRtdTypesProjectFile?
---@field write_project_file fun(project_file_json: ProjectRtdTypesProjectFile)
---@field add_rtd fun(name: string)
---@field remove_rtd fun(name: string)
---@field set_dir_as_project fun(directory: string)
---@field set_current_project_dir fun(directory: string)
---@field get_all_rtd_names fun(): string[]
---@field get_all_confiigured_rtd_names fun(): string[]
local M = {}

-- #region Project root directory

---Get the path to the current project directory
---@return string?
function M.get_project_directory()
    return Config.done.current_project_directory
end

---Get the path to the current project configuration directory
---@return string?
function M.get_project_configuration_directory()
    return Config.done.current_project_configuration_directory
end

---Set a directory as a project root directory
---Does not changes the current project, its configuration and loaded runtime directories. You need to restart Neovim in order top apply the
---changes.
---@param directory? string Directory to be set as a project. If not provided, use the current working directory
function M.set_dir_as_project(directory)
    directory = directory or Config.merged.cwd or ""
    directory = Text.add_trailing_slash(directory)
    local config_dir_path = directory .. Config.merged.project_config_subdir

    -- Creates the directory if it does not exist
    if vim.fn.isdirectory(config_dir_path) == 0 then
        vim.fn.mkdir(config_dir_path, "p", 448) -- '448' is '0700'
    end

    -- Creates the local spell_adds directory if it does not exist
    local spell_adds_dir = config_dir_path .. "/spell_adds"
    if vim.fn.isdirectory(spell_adds_dir) == 0 then
        vim.fn.mkdir(spell_adds_dir, "p", 448) -- '448' is '0700'
    end

    -- Does not create the configuration file if it already exists

    local config_file_path = Config.done.project_config_file
    local config_file_handler = io.open(config_file_path, "r")

    if config_file_handler then
        return
    end

    -- Creates a empty configuration file

    config_file_handler = io.open(config_file_path, "a+")

    if config_file_handler then
        config_file_handler:write("{}")
        config_file_handler:close()
    end
end

---Change the current project directory.
---Runtime directories already enabled will not be disabled.
---***NOTE***: can not load all project features. Some features must be enabled before Neovim start. These features can not be
---loaded.
---@param directory string Path of the project to load.
function M.set_current_project_dir(directory)
    directory = Text.add_trailing_slash(directory)

    local done = Config.done
    done.current_project_directory = directory
    done.current_project_configuration_directory = directory .. Config.merged.project_config_subdir
    done.project_config_file_abs = directory .. done.project_config_file

    for _, rtd_name in pairs(M.read_project_file() and Cache.project.configured_rtd_names or {}) do
        local _ = ApiRtd.RuntimeDir:new(rtd_name) -- The Rtd is automatically added to the cache, so discards the returned value
    end

    -- Update the runtime directories
    done.rtds = Cache.rtd
end

---read the project file and returns the names of its runtime directories
---@return ProjectRtdTypesProjectFile?
---@nodiscard
function M.read_project_file()
    local file_handler = io.open(Config.done.project_config_file_abs, "r")

    if not file_handler then
        return
    end

    ---Project configuration file
    local project_file_content = vim.secure.read(Config.done.project_config_file_abs)
    if not project_file_content then
        return
    end

    ---Project file converted to Lua Table
    ---@type ProjectRtdTypesProjectFile
    local project_file_json = vim.json.decode(project_file_content)
    if not Check.project_file_is_valid(project_file_json, true) then
        return
    end

    -- Updates the cache
    Cache.project.configured_rtd_names = project_file_json.runtime_dirs or {}
    return project_file_json
end

---Write the runtime directories to the project file
---This function overrides the project file
---@param project_file_json ProjectRtdTypesProjectFile Override the file with these runtime directories
function M.write_project_file(project_file_json)
    local file_handler = io.open(Config.done.project_config_file_abs, "w")
    if not file_handler then
        return
    end

    local file_content = vim.json.encode(project_file_json)
    file_handler:write(file_content)
    file_handler:close()

    -- Updates the cache
    Cache.project.configured_rtd_names = project_file_json.runtime_dirs
end

---Add runtime directories to the current project.
---This function does not apply these runtime directories. You need to restart Neovim in order to apply the changes.
---@param names string[] Name of the runtime directories to add to the current project
function M.add_rtd(names)
    local project_file = M.read_project_file() or {}
    project_file.runtime_dirs = project_file.runtime_dirs or {}

    for _, wanted_rtd_name in ipairs(names) do
        local add_wanted_rtd_name = true

        -- Does not add the runtime directory if is already is in the configuration file
        for _, enabled_rtd_name in pairs(project_file.runtime_dirs) do
            if enabled_rtd_name == wanted_rtd_name then
                add_wanted_rtd_name = false
                break
            end
        end

        if add_wanted_rtd_name then
            table.insert(project_file.runtime_dirs, wanted_rtd_name)
        end
    end

    -- Add the runtime directories to the configuration file
    M.write_project_file(project_file)
end

---Remove some runtime directory from the current project
---This function does not disable the runtime directories. You need to restart Neovim in order to apply the changes.
---@param names string[] Names of the runtime directories to remove from the current project
function M.remove_rtd(names)
    ---@type string[]
    local rtd_to_maintain = {}

    local enabled_rtds = M.read_project_file() and Cache.project.configured_rtd_names or {}

    for _, enabled_rtd_name in pairs(enabled_rtds) do
        local maintain_rtd = true

        -- Remove the runtime directory if it is in the `names` list
        for _, wanted_rtd_name in pairs(names) do
            if enabled_rtd_name == wanted_rtd_name then
                maintain_rtd = false
                break
            end
        end

        if maintain_rtd then
            table.insert(rtd_to_maintain, enabled_rtd_name)
        end
    end

    -- Add the runtime directives to the configuration file
    M.write_project_file(rtd_to_maintain)
end

-- #endregion

---Return the names of all runtime directories. Also return the names of the runtime directories that are not loaded.
---This function only updates the runtime directories names once in a Neovim session. If you manually created some runtime directory, you
---need to restart Neovim in order to apply the changes.
---@return string[]
---@nodiscard
function M.get_all_rtd_names()
    if Cache.project.all_rtd_names then
        return Cache.project.all_rtd_names
    end

    ---Save the name of all runtime directories in this variable
    ---@type string[]
    local names = {}

    for _, path in pairs(Config.merged.sources) do
        local ApiSource = require("project_runtime_dirs.api.source")
        local source = ApiSource.RuntimeSource:new(path)

        -- A runtime source create from a runtime source path will always exist (will never be `nil`). The following condition is to remove
        -- the type checking errors
        if source == nil then
            break
        end

        for _, rtd_name in pairs(source:get_rtds(true)) do
            table.insert(names, rtd_name)
        end
    end

    Cache.project.all_rtd_names = names
    return names
end

---Return the names of all configured runtime directories. Also return the names of the runtime directories that are not loaded.
---The API only updates the runtime directories names when the API change or read the project configuration file. If you manually add a
---runtime directory, you need to restart Neovim in order to apply the changes.
---@return string[]
---@nodiscard
function M.get_all_confiigured_rtd_names()
    return Cache.project.configured_rtd_names or {}
end

return M
