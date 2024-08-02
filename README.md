# Project Runtime Directories (Neovim plugin)

Simple Neovim Plugin to automatically load project specific runtime directories and configurations.


## The problem

Sometimes I want to apply some configuration only to a specific project. Editing my Neovim configuration files every time I change to
another project is annoying. I want a more easy way to apply configuration to specific projects and an API to manage them.


## Possible solutions

* Use `exrc`. This Vim/Neovim feature allows the user to execute custom scripts in the current working directory and apply local
  configurations. Works fine for a simple configuration, but does not allow more complex customization (Tree-sitter queries, by example). If
  properly configured, the user will be asked before sourcing the script, so nothing will be loaded without your permission. If you did not
  created the file, you still need to check it before executing. Also `exrc` only executes its files if them are in the current working
  directory. They are not executed if opening Neovim in a sub-directory. Brief: only runs the code that you allows, but has few features.

* Add the current working directory to the runtime path variable (`vim.opt.rtp`). This allows to user to place the local configurations in
  the current directory, and Neovim will have access to all the runtime paths specified in `:help runtimepath`. But result in security
  issues. You can not open Neovim in directories that are not trusted because the code in these directories will be executed without any
  security check or sand boxing. As with `exrc` this solution does not works if opening Neovim in a sub-directory of the project. Brief: has
  many features, but is not secure and does not manage configurations common to different projects.

* Use `exrc` to add a configuration directory to your `vim.opt.rtp` global option. You have the control o what code will be executed by
  `exrc`, and this solution is too versatile as the `vim.opt.rtp` option. You can create a 'nvim/' directory in your project (the name is an
  example) and add it to `vim.opt.rtp` with `exrc`. This is a good solution to most users. You can also put configurations common to similar
  projects in a folder and add this folder to the `vim.opt.rtp` of all projects that use them. Example: create a
  '\~/.config/nvim/projects/arduino/' folder and add the following lines tho your '.nvim.lua' file:

  ```lua
  local arduino_folder = vim.fn.stdpath('config') .. '/projects/arduino'
  vim.opt.rtp:append(arduino_folder)
  dofile(arduino_folder .. '/init.lua')  -- Place your configuration in this file
  ```

  Open Neovim in the same directory as the '.nvim.lua' file, and `exrc` will ask if you what to source the '.nvim.lua' file. If you allow
  it, the '\~/.config/nvim/arduino' folder will be added to your `vim.opt.rtp` global option, and the '\~/.config/nvim/arduino/init.lua'
  file will also be sourced. As the `exrc`, solution this does not works if opening Neovim in a sub-directory of the project, but can manage
  more complex configuration (Like Tree-sitter queries).

  Brief: you have control to code that will be executed (you need to checked the scripts that `exrc` sources), has many features and can
  manage configurations to different projects. But you need to do some manual configuration every time you configure a project, you have not
  an API to manage the project configurations, and you need to open Neovim in the same directory as the '.nvim.lua' file. If these
  limitations are not a problem to you, you do not need this plugin. Just use `exrc` with `vim.opt.rtp`.


### This plugin solution

Works like the `exrc` and `vim.opt.rtp` solution. You also need to create a folder with the configurations (named a runtime directory). But,
instead of creating a '.nvim.lua' file to apply the specific configurations, you have an API and commands.

This plugin will load some runtime directories (add them to `vim.opt.rtp`) based in a project configuration file. This plugin will read the
names of the runtime directories in this file and load them. See the list of features bellow.

The current working directory will not be added to `vim.opt.rtp`, so the user can open Neovim in any project directory.

The runtime directories must not be accessible by other users or not trusted software.

> [!WARNING]
>
> This plugin presumes that only you have access to your file system, and only you can edit the runtime directories. If other person or
> software can edit the contents of these directories, your machine is compromised, and there are nothing we can do to improve security in
> your runtime directories and configurations.


## What this plugin is not

* A solution to manage project configurations with other users. This plugin only manages the configuration in your machine. Other users can
  not access them.

* A solution to manage templates.


## Naming conventions

* "current working directory": value returned by the `vim.fn.getcwd()` function. The user can override this in its configuration. It can be
  abbreviated to "current directory"

* "project root directory": base directory of a project. This type of directory is defined by the "project root file".

* "project root file": a directory that has this file is considered a root project directory. Can be overridden by the user.

* "current project directory": a project root directory defined by this plugin. The default configuration will search from the current
  working directory to the top most directory by a project root directory and select the first one. Example: if the user is inside the
  '\~/my_project/sub_dir/' folder, the default configuration will test if this directory is a project root folder. If `true`, will set this as the
  "current project folder". If `false` will try '\~/my_project/' and apply the some logic. This process will be repeated until find a
  project or end the available directories. The user can override this behavior.

* "runtime directory": directory that hold some project configurations and can be added to `vim.opt.rtp`. A configuration directory this
  plugin manages unless otherwise stated. Can be abbreviated to "Rtd".

* "configured runtime directories": runtime directories configured in the project root file. This plugin will try to load them as possible.
  This plugin will not enable a configured runtime directory if it does not exist.

* "enabled runtime directories": runtime directories loaded in the current Neovim session (added to `vim.opt.rtp`).

* "runtime source": where to save the runtime directories. A folder that contains some runtime directories.

> [!NOTE]
>
> Sometimes "folder" can be used to refer to "directory".


## Features

* Automatically add the project runtime directories to the runtime path (`vim.opt.rtp`).

* API and commands to manage runtime directories. Set a directory as a project root folder, add and remove runtime directories from the
  current project. Edit files and folders in a runtime directory.

* Support to multiple runtime directory in the same project.

* Support to inheritance of runtime directories. A runtime directory can automatically load another one.

* Set the project directory based in the configuration file founded, so you can open Neovim in a sub-directory in the current project and it
  will recognize correctly the project root folder.


## Configuration

Ensures that this plugin is one of the first in the startup sequence.

Example of [lazy.nvim](https://github.com/folke/lazy.nvim) configuration:

```lua
return {
    {
        'LucasAVasco/project_runtime_dirs.nvim',
        priority = 10500,  -- Should be a high value to start before other plugins

        ---@module 'project_runtime_dirs.config'
        ---@type ProjectRtdOptions
        opts = {}, -- To override the default configuration

        config = true,
    }
}
```

The configuration documentation can be found at [config.lua](./lua/project_runtime_dirs/config.lua)

<!-- TODO(LucasAVasco): Generate markdown and vimdoc from the source code -->


## Usage

This plugin adds user commands and an API to manage runtime directories.


### Commands

If you enabled the user commands in your configurations (default behavior), these user commands are available:

* 'ProjectRtdSetRoot': Set a folder as a project root directory. If a folder is not provided, use the current working directory.

* 'ProjectRtdAddRtd': Add some runtime directories to the current project.

* 'ProjectRtdRemoveRtd': Remove some runtime directories from the current project.

* 'ProjectRtdEditRtd': Edit a file or folder in a runtime directory. Usage: `ProjectRtdEditRtd <rtd-name> <file-path>`.

* "ProjectRtdShowContext": Show the plugin context: merged configuration, current project directory, runtime directory data.

> [!NOTE]
>
> The commands that manage the runtime directories (add, remove, etc.) are not applied to the current Neovim session. You need to restart
> Neovim in order to apply the changes


### API

All the API modules can be found in the [API directory](./lua/project_runtime_dirs/api/). The API development follows [semantic
versioning](https://semver.org/).

<!-- TODO(LucasAVasco): Generate markdown and vimdoc from the API files -->


## Useful tip

The project root file should not be version by Git because the runtime directories are not shared with other users. So you should add this
file to your git ignore file. It is a good idea to put it in the file specified by your
[core.excludesFile](https://git-scm.com/docs/git-config#Documentation/git-config.txt-coreexcludesFile) configuration option. Usually the
'\~/.config/git/ignore' file in an Unix system.