---Module with the text utilities used by the `project_runtime_dirs.nvim` plugin
---@class (exact) ProjectRtdText
---@field remove_trailing_slash fun(text: string): string
---@field add_trailing_slash fun(text: string): string
---@field remove_substring_end fun(text: string, sub_str: string): string
---@field remove_newlines fun(text: string): string
local M = {}


---Ensure that the provided text has not a trailing slash
---@param text string Text with or without a trailing slash
---@return string text_without_trailing_slash
function M.remove_trailing_slash(text)
    if text:sub(#text, #text) ~= '/' then
        text = text:sub(1, #text)
    end

    return text
end


---Ensure that the provided text has a trailing slash
---@param text string Text with or without a trailing slash
---@return string text_with_trailing_slash
function M.add_trailing_slash(text)
    if text:sub(#text, #text) ~= '/' then
        text = text .. '/'
    end

    return text
end


---Remove a sub-string at the end of the text (if this sub-string exists)
---@param text string Remove the sub-string from this text
---@param sub_str string Sub-string to be removed
---@return string text_without_sub_string
function M.remove_substring_end(text, sub_str)
    local start_pos = #text - #sub_str +1  -- Index of the first character of the sub-string in the text

    if text:sub(start_pos, #text) == sub_str then
        return text:sub(1, start_pos - 1)
    else
        return text
    end
end


---Remove the newline character of a text
---@param text string Remove the newlines from this text
---@return string text_without_newlines
function M.remove_newlines(text)
    local res = text:gsub('\n', '')
    return res
end


return M