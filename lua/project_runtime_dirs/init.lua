local Config = require("project_runtime_dirs.config")
local ApiRtd = require("project_runtime_dirs.api.rtd")
local Cache = require("project_runtime_dirs.cache")
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

    -- Ensures that all paths have a trailing slash
    for i = 1, #merged.sources do
        merged.sources[i] = Text.add_trailing_slash(merged.sources[i])
    end

    -- Project directory and runtime directories
    local project_dir = merged.get_project_dir(merged)

    if project_dir then
        project_dir = Text.add_trailing_slash(project_dir)
        done.current_project_directory = project_dir
        done.project_root_file_abs = project_dir .. merged.project_root_file

        for _, rtd_name in pairs(ApiProject.read_project_file() or {}) do
            local _ = ApiRtd.RuntimeDir:new(rtd_name) -- The Rtd is automatically added to the cache, so discards the returned value
        end
    end

    -- Update the runtime directories
    done.rtds = Cache.rtd

    -- User commands
    if merged.load_user_commands then
        require("project_runtime_dirs.commands")
    end
end

return M
