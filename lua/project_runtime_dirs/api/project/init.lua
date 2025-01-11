local Config = require("project_runtime_dirs.config")
local Cache = require("project_runtime_dirs.cache")
local Check = require("project_runtime_dirs.check")
local Text = require("project_runtime_dirs.text")

-- API

---API to manage the current project of the `project_runtime_dirs.nvim` plugin and its runtime directories
---@class (exact) ProjectRtdApiProject
---@field get_project_directory fun(): string?
---@field read_project_file fun(): string[]?
---@field write_project_file fun(runtime_dirs: string[])
---@field add_rtd fun(name: string)
---@field remove_rtd fun(name: string)
---@field set_dir_as_project fun(directory: string)
---@field get_all_rtd_names fun(): string[]
---@field get_all_confiigured_rtd_names fun(): string[]
local M = {}

-- #region Project root file

---Get the path to the current project directory
---@return string?
function M.get_project_directory()
    return Config.done.current_project_directory
end

---Set a directory as a project root directory
---Does not changes the current project, its configuration and loaded runtime directories. You need to restart Neovim in order top apply the
---changes.
---@param directory? string Directory to be set as a project. If not provided, use the current working directory
function M.set_dir_as_project(directory)
    directory = directory or Config.merged.cwd or ""
    directory = Text.add_trailing_slash(directory)

    -- Touch the file
    local file_handler = io.open(directory .. Config.merged.project_root_file, "a+")

    if file_handler then
        file_handler:write("")
        file_handler:close()
    end
end

---read the project file and returns the names of its runtime directories
---@return string[]?
---@nodiscard
function M.read_project_file()
    -- checks the file size
    local file_handler = io.open(Config.done.project_root_file_abs, "r")

    if not file_handler then
        return
    end

    ---@type string
    local content, extra_content = file_handler:read(100000, 1)
    file_handler:close()

    --- The `extra_content` variable only have a value (different form `nil`) if the `content` variable can not hold all the file content
    --- because the file is too long. This is an error, and this function will abort the operation
    if extra_content ~= nil then
        vim.notify(
            ('Error parsing the file "%s". File is too long.'):format(Config.done.project_root_file_abs),
            vim.log.levels.ERROR
        )

        return
    end

    -- File is not too long. We can parse it

    ---@type string[]
    local res = {}

    if content then
        for line in content:gmatch("[^\n]+") do
            ---@cast line string

            line = Text.remove_newlines(line)

            -- Ensures the name is valid
            if not Check.rtd_name_is_valid(line, true) then
                break
            end

            table.insert(res, line)
        end
    end

    -- Updates the cache
    Cache.project.configured_rtd_names = res
    return res
end

---Write the runtime directories to the project file
---This function overrides the project file
---@param runtime_dirs string[] Override the file with these runtime directories
function M.write_project_file(runtime_dirs)
    local file_handler = io.open(Config.done.project_root_file_abs, "w")

    if file_handler then
        for i = 1, #runtime_dirs do
            file_handler:write(runtime_dirs[i])

            -- Does not adds a new lien to the last line
            if i ~= #runtime_dirs then
                file_handler:write("\n")
            end
        end

        file_handler:close()

        -- Updates the cache
        Cache.project.configured_rtd_names = runtime_dirs
    end
end

---Add runtime directories to the current project.
---This function does not apply these runtime directories. You need to restart Neovim in order to apply the changes.
---@param names string[] Name of the runtime directories to add to the current project
function M.add_rtd(names)
    local enabled_rtds = M.read_project_file() or {}

    for _, wanted_rtd_name in pairs(names) do
        local add_wanted_rtd_name = true

        -- Does not add the runtime directory if is already is in the configuration file
        for _, enabled_rtd_name in pairs(enabled_rtds) do
            if enabled_rtd_name == wanted_rtd_name then
                add_wanted_rtd_name = false
                break
            end
        end

        if add_wanted_rtd_name then
            table.insert(enabled_rtds, wanted_rtd_name)
        end
    end

    -- Add the runtime directives to the configuration file
    M.write_project_file(enabled_rtds)
end

---Remove some runtime directory from the current project
---This function does not disable the runtime directories. You need to restart Neovim in order to apply the changes.
---@param names string[] Names of the runtime directories to remove from the current project
function M.remove_rtd(names)
    ---@type string[]
    local rtd_to_maintain = {}

    local enabled_rtds = M.read_project_file() or {}

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
---The API only updates the runtime directories names when the API change or read the project root file. If you manually add a runtime
---directory, you need to restart Neovim in order to apply the changes.
---@return string[]
---@nodiscard
function M.get_all_confiigured_rtd_names()
    return Cache.project.configured_rtd_names or {}
end

return M
