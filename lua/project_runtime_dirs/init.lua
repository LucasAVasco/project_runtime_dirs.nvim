local Config = require("project_runtime_dirs.config")
local Text = require("project_runtime_dirs.text")
local ApiProject = require("project_runtime_dirs.api.project")

---Module to initialize the `project_runtime_dirs.nvim` plugin
---@class (exact) ProjectRtdInitSetup
---@field setup fun(opts: ProjectRtdOptions)
local M = {}

---Setup the `working_runtime_path.nvim` plugin
---@param opts? ProjectRtdOptions Options to pass to `working_runtime_path.nvim`
function M.setup(opts)
    local done = Config.done
    local merged = vim.tbl_deep_extend("force", Config.default, opts)
    Config.merged = merged

    -- Configuration file inside the project directory
    done.project_config_file = merged.project_config_subdir .. "config.json"

    -- Ensures that all paths have a trailing slash
    for i = 1, #merged.sources do
        merged.sources[i] = Text.add_trailing_slash(merged.sources[i])
    end

    merged.cwd = Text.add_trailing_slash(merged.cwd)
    merged.project_config_subdir = Text.add_trailing_slash(merged.project_config_subdir)

    -- Project directory and runtime directories
    local project_dir = merged.get_project_dir(merged)

    if project_dir then
        ApiProject.set_current_project_dir(project_dir)
    else
        done.rtds = {}
    end

    -- User commands
    if merged.load_user_commands then
        require("project_runtime_dirs.commands")
    end
end

return M
