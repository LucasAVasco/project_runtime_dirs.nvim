local Config = require('project_runtime_dirs.config')
local Text = require('project_runtime_dirs.text')

-- API

local ApiProject = require('project_runtime_dirs.api.project')


vim.api.nvim_create_user_command('ProjectRtdSetRoot', function(arguments)
    ApiProject.set_dir_as_project(arguments.fargs[1] or '.')
end, {
    desc = 'Set a folder as a project root directory. If a folder is no provided, use the current working directory',
    nargs = '?',
    complete = 'dir'
})


vim.api.nvim_create_user_command('ProjectRtdAddRtd', function(arguments)
    ApiProject.add_rtd(arguments.fargs)
end, {
    desc = 'Add some runtime directories to the current project',
    nargs = '+',
    complete = function()
        return ApiProject.get_all_rtd_names()
    end
})


vim.api.nvim_create_user_command('ProjectRtdRemoveRtd', function(arguments)
    ApiProject.remove_rtd(arguments.fargs)
end, {
    desc = 'Remove some runtime directories from the current project',
    nargs = '+',
    complete = function()
        return ApiProject.get_all_rtd_names()
    end
})


-- #region Commands to edit runtime directory files

---Get the completion list (used in `complete` functions) with the files and folders inside the provided runtime directory
---@param rtd RuntimeDir Search files and directories in this runtime directory
---@param argument_lead string The path being typed. The completion is based in this file. Relative to the runtime directory
---@return string[] completions Possible paths to complete
local function get_complete_list_from_rtd_files(rtd, argument_lead)
    ---@type string[]
    local completions = {}

    local top_dir = vim.fs.dirname(argument_lead)
    local top_dir_files = rtd:list_files(top_dir, true)

    if top_dir_files then
        for _, file in pairs(top_dir_files) do
            local sub_path = top_dir .. '/' .. file

            -- Removes the leading './'
            if sub_path:sub(1, 2) == './' then
                sub_path = sub_path:sub(3, #sub_path)
            end

            -- Adds a trailing '/' to directories
            if rtd:isdirectory(sub_path) then
                sub_path = sub_path .. '/'
            end

            table.insert(completions, sub_path)
        end
    end

    return completions
end


vim.api.nvim_create_user_command('ProjectRtdEditRtd', function(arguments)
    local ApiProjectEnabledRtd = require('project_runtime_dirs.api.project.enabled_rtd')
    local rtd = ApiProjectEnabledRtd.get_by_name(arguments.fargs[1])

    if rtd then
        rtd:edit(arguments.fargs[2] or '.', true)
    end
end, {
    desc = 'Edit a file or folder in a runtime directory. Usage: `ProjectRtdEditRtd <rtd-name> <file-path>`',
    nargs = '+',

    ---Completion function
    ---@param argument_lead string Argument being typed
    ---@param full_command string Full command typed
    complete = function(argument_lead, full_command, _)
        local ApiProjectEnabledRtd = require('project_runtime_dirs.api.project.enabled_rtd')
        ---@type string[]
        local command = vim.fn.split(full_command)

        -- Number of commands that the user is typing. The space at the last character implies in that the last command is finished (select
        -- the next command)
        local size = #command

        if full_command:sub(#full_command, #full_command) == ' ' then
            size = size + 1
        end

        -- Selecting the runtime directory
        if size == 2 then
            return ApiProjectEnabledRtd.get_all_names()

        -- Selecting the file or folder
        elseif size == 3 then
            local rtd = ApiProjectEnabledRtd.get_by_name(command[2])
            if rtd then
                if full_command:sub(#full_command, #full_command) == ' ' or #command == 3 then
                    return get_complete_list_from_rtd_files(rtd, argument_lead)
                end
            end
        end
    end
})

-- #endregion


-- #region `ProjectRtdShowContext` command

---Convert a list of strings as a unique string (to show the data)
---@param list string[]
---@return string
local function list2string(list)
    local res = ''
    for _, item in pairs(list) do
        res = res .. item .. ', '
    end
    return res
end

-- --[[markdown]]
local rtd_data_template = [[
### %s

* absolute path: '%s'

* Inherits: %s

]]

---Get the runtime directory data formatted as a markdown string
---@param runtime_dir RuntimeDir
---@return string
local function get_rtd_data(runtime_dir)
    return rtd_data_template:format(runtime_dir.name, runtime_dir.path, list2string(runtime_dir.deps.names))
end


-- --[[markdown]]
local shown_interface_template = [[
# `project_runtime_dirs.nvim` interface

## User configuration (merged with the defaults)
```%s
%s
```

## Current project directory

* Path: '%s'


## Available runtime directories

Name of all runtime directories (also the not enabled): %s


## Configured runtime directories

Name of all runtime directories in the configuration file: %s

> [!Note]
>
> These runtime directories will not be enabled if theirs path does not exist


## Enabled runtime directories

Total: %d

%s
]]


---Get the content to be shown in the `ProjectRtdShowContext` command formatted as markdown
---@return string[]
local function get_shown_interface()
    local ApiProjectEnabledRtd = require('project_runtime_dirs.api.project.enabled_rtd')
    local enabled_rtd_content = ''

    for _, rtd in pairs(ApiProjectEnabledRtd.get_all()) do
        enabled_rtd_content = enabled_rtd_content .. get_rtd_data(rtd) .. '\n'
    end

    -- List of lines
    local content = shown_interface_template:format(
        'lua', vim.inspect(Config.merged),
        Config.done.current_project_directory,
        list2string(ApiProject.get_all_rtd_names()),
        list2string(ApiProject.get_all_confiigured_rtd_names()),
        #ApiProjectEnabledRtd.get_all(), enabled_rtd_content
    )

    ---@type string[]
    local content_lines = {}
    for line in content:gmatch('[^\n]*\n') do
        table.insert(content_lines, Text.remove_newlines(line))
    end

    return content_lines
end


local rtd_show_win_active = false  -- Does not creates a new window if this variable is `true`

vim.api.nvim_create_user_command('ProjectRtdShowContext', function()
    if rtd_show_win_active then
        return
    end

    -- Buffer with the contents
    local buffer_nr = vim.api.nvim_create_buf(false, true)

    for key, value in pairs({
        filetype='markdown',
        buftype = 'nofile',
    }) do
        vim.bo[buffer_nr][key] = value
    end

    -- Content to be placed in the buffer
    vim.api.nvim_buf_set_lines(buffer_nr, 0, -1, true, get_shown_interface())
    vim.bo[buffer_nr].modifiable = false

    -- Window configuration
    ---@type vim.api.keyset.win_config
    local win_config = {
        col = 10,
        row = 5,
        width = vim.o.columns - 20,
        height = vim.o.lines - 10,
    }

    local window_id = vim.api.nvim_open_win(buffer_nr, true, vim.tbl_deep_extend('force', Config.merged.ui or {}, win_config))

    for key, value in pairs({
        conceallevel = 3
    }) do
        vim.wo[window_id][key] = value
    end

    -- Closing with the `:quit` command
    vim.api.nvim_create_autocmd('WinClosed', {
        buffer = buffer_nr,
        callback = function()
            rtd_show_win_active = false
            vim.api.nvim_win_close(window_id, true)
            vim.api.nvim_buf_delete(buffer_nr,{
                force = true,
                unload=true,
            })
        end
    })

    -- Key map to close the window
    local function close_window()
        rtd_show_win_active = false
        vim.api.nvim_win_close(window_id, true)
        vim.api.nvim_buf_delete(buffer_nr, {
            force = true,
        })
    end

    local keymap_opts = {
        buffer = buffer_nr,
        remap = false,
        silent = true,
    }

    vim.keymap.set('n', '<ESC>', close_window, keymap_opts)
    vim.keymap.set('n', 'q', close_window, keymap_opts)

    -- Disable any other call to this command
    rtd_show_win_active = true
end, {
    desc = 'Show the plugin context: merged configuration, current project directory, runtime directory data',
})

-- #endregion