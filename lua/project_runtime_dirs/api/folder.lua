local Text = require('project_runtime_dirs.text')


---API to manage folders of the `project_runtime_dirs.nvim` plugin
---@class (exact) ProjectRtdApiFolder
---@field DirManager DirManager
local M = {}


-- #region Directory manager class

---Class to manage a directory
---@class (exact) DirManager
---@field path string Absolute path to the directory
---@field __index? DirManager
M.DirManager = { }
M.DirManager.__index = M.DirManager


---Get the absolute path of a sub-path in the directory
---@param sub_path string
---@return string
---@nodiscard
function M.DirManager:get_abs_path(sub_path)
    -- Remove the current directory at the end (unnecessary and may cause bugs with the `mkdir function`)
    return Text.remove_substring_end(self.path .. sub_path, '/.')
end


---Create a folder inside the directory
---@param sub_path string Path to the folder to create. Relative to the directory
---@param flags? string Same as the `flags` attribute of the `vim.fn.mkdir` function
---@param prot? number Permission mask. Same as the `prot` attribute of the `vim.fn.mkdir()` function. The default is '0700'
function M.DirManager:mkdir(sub_path, flags, prot)
    local abs_path = self:get_abs_path(sub_path)

    if vim.fn.isdirectory(abs_path) == 0 then  -- If the folder does not exist
        -- Create the folder. Use '0700' as the default permission. Only the user has access, can edit or search files in the directory.
        -- Useful in configuration files if other users are not allowed to access them
        vim.fn.mkdir(abs_path, flags, prot or 448) -- '448' is '0700'
    end
end


---Create a file inside the directory
---@param sub_path string Path to the file. Relative to the directory
---@param create_parent_dir? boolean Automatically create the parent folder if it does not exist
function M.DirManager:touch(sub_path, create_parent_dir)
    local abs_path = self:get_abs_path(sub_path)

    if vim.fn.filereadable(abs_path) == 0 then  -- If the file does not exist
        if create_parent_dir then
             self:mkdir(vim.fs.dirname(sub_path), 'p')
        end
        vim.fn.writefile({''}, abs_path, 'a')  -- Touch the file
    end
end


---Edit a file or folder inside the directory
---Use the `:edit` command
---@param sub_path string Path to the file or folder. Relative to the directory
---@param create_parent_dir? boolean Automatically create the parent folder if it does not exist
function M.DirManager:edit(sub_path, create_parent_dir)
    if create_parent_dir then
         self:mkdir(vim.fs.dirname(sub_path), 'p')
    end

    local abs_path = self:get_abs_path(sub_path)
    abs_path = abs_path:gsub('%%', '\\%%')  -- Escape '%', required to use `vim.cmd.edit`
    vim.cmd({cmd = 'edit', args = {abs_path}})
end


---Check if the provided file is readable
---@param sub_path string Path to the file. Relative to the directory
---@return boolean
---@nodiscard
function M.DirManager:filereadable(sub_path)
    local abs_path = self:get_abs_path(sub_path)

    return vim.fn.filereadable(abs_path) == 1
end


---Check if a folder exist in the directory
---@param sub_path string Path to the folder to check. Relative to the directory
---@nodiscard
function M.DirManager:isdirectory(sub_path)
    local abs_path = self:get_abs_path(sub_path)

    return vim.fn.isdirectory(abs_path) == 1
end


---Open a file and return the file handler
---@param sub_path string Path to the file to open. Relative to the directory
---@param mode? openmode Same from `io.open()` function
---@return file*? file_handler, string? error_message
function M.DirManager:open(sub_path, mode)
    local abs_path = self:get_abs_path(sub_path)

    return io.open(abs_path, mode)
end


---Equivalent to the `vim.uv.fs_scandir` function, but applies to a sub-folder inside the directory
---@param sub_path string Path to pass to `vim.uv.fs_scandir` function. Relative to the directory
---@return uv_fs_t? fs_handler, string? error_name, string? error_message
---@nodiscard
function M.DirManager:fs_scandir(sub_path)
    local abs_path = self:get_abs_path(sub_path)

    -- Create a handler to query the files
    return vim.uv.fs_scandir(abs_path)
end


---Get a list of files and folders inside the working run time directory
---@param sub_path string List files and folders inside this sub directory
---@param ignore_errors? boolean Does not notify if can not access the folder
---@return string[]? files Relative to the *sub_path* directory. Returns nil if it can not access the *sub_path* directory
---@nodiscard
function M.DirManager:list_files(sub_path, ignore_errors)
    local abs_path = self:get_abs_path(sub_path)

    -- Handler to query the files
    local fs_handler, error_name = vim.uv.fs_scandir(abs_path)

    ---@type string[]
    local files = {}

    if fs_handler == nil then
        if not ignore_errors then
            vim.notify(('Can not access files inside: "%s". Error name: %s'):format(abs_path, error_name), vim.log.levels.ERROR)
        end

        return
    end

    -- Fulfills the `files` variable
    while true do
        local next_file = vim.uv.fs_scandir_next(fs_handler)

        if next_file then
            table.insert(files, next_file)
        else
            break
        end
    end

    return files
end


---Create an object to manage a directory
---@param path string Path to the directory to manage
---@return DirManager dir Object to manage the *path* directory
---@nodiscard
function M.DirManager:new(path)
    ---New directory manager
    ---@type DirManager
    local new = {
        path = Text.add_trailing_slash(path),
    }

    setmetatable(new, M.DirManager)

    return new
end

-- #endregion


return M