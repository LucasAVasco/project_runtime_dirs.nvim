---Module to manage the configurations and options of the `project_runtime_dirs.nvim` plugin
---@class (exact) ProjectRtdConfig
---@field default ProjectRtdOptions
---@field merged ProjectRtdOptions
---@field done ProjectRtdConfigCfgDone
local M = {}

---Configuration that can be overridden by the user options
---@class (exact) ProjectRtdOptions
---@field cwd? string Override the current working directory
---@field sources? string[] Runtime sources. Folders to search by runtime directories
---@field project_root_file? string Folders with this file are project folders. Saves the runtime directories to enable
---@field folder_is_project? fun(folder: string, config: ProjectRtdOptions): boolean Return if a folder is a project root directory
---@field get_project_dir? fun(config: ProjectRtdOptions): string? Return the current project directory
---@field load_user_commands? boolean Set to `false` to disable user commands. You can still use the API
---@field ui? vim.api.keyset.win_config Configuration of the windows that this plugin creates to show the plugin status
M.default = {
    cwd = vim.fn.getcwd(),

    sources = {
        vim.fn.stdpath("data") .. "/runtime_dirs/",
        vim.fn.stdpath("config") .. "/runtime_dirs/", -- Runtime directories that you may want to track with your configuration files
    },

    project_root_file = ".nvim-project-runtime.json",

    folder_is_project = function(folder, config)
        local file = folder .. "/" .. config.project_root_file

        return (vim.fn.isdirectory(file) + vim.fn.filereadable(file)) > 0
    end,

    get_project_dir = function(config)
        local cwd = config.cwd or "" -- The empty string is to disable the type checking error

        -- Checks in the current directory
        if config.folder_is_project(cwd, config) then
            return cwd
        end

        -- Checks in the parent directories
        for dir in vim.fs.parents(cwd or "") do
            if config.folder_is_project(dir, config) then
                return dir
            end
        end
    end,

    load_user_commands = true,

    ui = {
        relative = "editor",
        style = "minimal",
        border = "rounded",
    },
}

---Merge of the default configuration and the user provided options. The user options have high priority.
---Can not be used before the plugin initialization.
---@type ProjectRtdOptions
---@diagnostic disable-next-line: missing-fields The fields will be fulfilled in the setup function
M.merged = {}

---Configuration defined after the plugin initialization. Can not be used before it.
---@class (exact) ProjectRtdConfigCfgDone
---@field rtds RuntimeDir[] Runtime directories of the current Neovim session
---@field current_project_directory? string Absolute path to the current project directory
---@field project_root_file_abs? string Absolute path to the file holding the runtime directories of the current project
---@diagnostic disable-next-line: missing-fields The fields will be fulfilled in the setup function
M.done = {}

return M
