local M = {}

---Show a notification with the plugin title
---@param message string Message to show
---@param level vim.log.levels|nil Notification level
function M.show(message, level)
    vim.notify(message, level, { title = "project_runtime_dirs.nvim" })
end

return M
