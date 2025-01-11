---Module to check the validity of the data used in the `project_runtime_dris.nvim` plugin
---@class (exact) ProjectRtdCheck
---@field get_rtd_name_max_size fun(): integer
---@field rtd_name_is_valid fun(name: string, notify?: boolean): boolean
local M = {}

local rtd_name_max_size = 500 -- Max size of each runtime directory name

---Return the maximum size allowed to a runtime directory name
---@return integer
function M.get_rtd_name_max_size()
    return rtd_name_max_size
end

---Check if the runtime directory name is valid
---@param name string Name of the runtime directory
---@param notify? boolean Show a notification if the name is not valid
---@return boolean name_is_valid
function M.rtd_name_is_valid(name, notify)
    -- Checks if name is empty
    local is_valid = name ~= ""

    if not is_valid then
        if notify then
            vim.notify(('Error parsing project name: "%s". Name is empty'):format(name), vim.log.levels.ERROR)
        end

        return false
    end

    -- Checks the size of the name
    is_valid = #name < rtd_name_max_size

    if not is_valid then
        if notify then
            vim.notify(
                ('Error parsing project name: "%s". Name is too long. Maximum of %d characters'):format(
                    name,
                    rtd_name_max_size
                ),
                vim.log.levels.ERROR
            )
        end

        return false
    end

    -- Checks the content of the name
    is_valid = name:match("^[%a%d_-]+$") ~= nil

    if not is_valid then
        if notify then
            vim.notify(
                ('Error parsing runtime directory name: "%s". Only letters, numbers and "_" are allowed'):format(name),
                vim.log.levels.ERROR
            )
        end

        return false
    end

    -- Fallback response
    return true
end

return M
