---@module "project_runtime_dirs.types.rtd"

local notification = require("project_runtime_dirs.notification")

---Module to check the validity of the data used in the `project_runtime_dris.nvim` plugin
---@class (exact) ProjectRtdCheck
---@field get_rtd_name_max_size fun(): integer
---@field rtd_name_is_valid fun(name: string, notify?: boolean): boolean
---@field project_file_is_valid fun(file_content_json: ProjectRtdTypesProjectFile, notify?: boolean): boolean
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
            notification.show(('Error parsing project name: "%s". Name is empty'):format(name), vim.log.levels.ERROR)
        end

        return false
    end

    -- Checks the size of the name
    is_valid = #name < rtd_name_max_size

    if not is_valid then
        if notify then
            notification.show(
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
            notification.show(
                ('Error parsing runtime directory name: "%s". Only letters, numbers and "_" are allowed'):format(name),
                vim.log.levels.ERROR
            )
        end

        return false
    end

    -- Fallback response
    return true
end

---Show a notification about an error parsing the project file.
---@param message string specific parsing error.
---@param notify boolean shows the notification.
local function notify_error_parsing_project_file(message, notify)
    if notify then
        notification.show("Error parsiong configuration file: '" .. message .. "'")
    end
end

---Check if the content of a project file is valid.
---@param file_content_json ProjectRtdTypesProjectFile JSON with the contents of the project file.
---@param notify boolean throw a notification if the content is invalid.
---@return boolean is_valid if the project file is valid.
function M.project_file_is_valid(file_content_json, notify)
    local is_valid = true
    if file_content_json.runtime_dirs then
        if type(file_content_json.runtime_dirs) ~= "table" then
            notify_error_parsing_project_file(
                "the argument `runtime_dirs` must be a list of runtime directories names `string[]`.",
                notify
            )
            is_valid = false
        else
            -- Checks each runtime directory
            for _, rtd in ipairs(file_content_json.runtime_dirs) do
                if not M.rtd_name_is_valid(rtd) then
                    notify_error_parsing_project_file(
                        'The provided runtime directory name is invalid: "' .. rtd .. '"',
                        notify
                    )
                    is_valid = false
                end
            end
        end
    end

    -- Fallback return
    return is_valid
end

return M
