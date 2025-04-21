local M = {}
local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local themes = require("telescope.themes")
local utils = require("buffer-manager.utils")
local config = require("buffer-manager.config").options
local pin = require("buffer-manager.pin")

function M.create_buffer_entry(entry)
    local cursor_pos = vim.api.nvim_buf_get_mark(entry.bufnr, '"')[1]
    local is_modified = vim.api.nvim_buf_get_option(entry.bufnr, "modified")
    local icon = utils.get_icon(entry.bufnr)
    local in_session = require("buffer-manager.session").is_in_session(entry.bufnr)
    local is_pinned = pin.is_pinned(entry.bufnr)
    local pin_icon = is_pinned and "📌 " or ""

    return {
        value = entry.name,
        display = string.format(
            "%s%s%s%s%d: %s%s",
            pin_icon,
            icon,
            in_session and config.sessions.indicator_icon .. " " or "",
            is_pinned and "" or "",
            cursor_pos,
            utils.format_path(entry.name),
            is_modified and " [+]" or ""
        ),
        ordinal = entry.name,
        bufnr = entry.bufnr,
        is_pinned = is_pinned,
    }
end

function M.open(opts)
    opts = opts or {}
    local buffers = {}

    -- Get pinned buffers first (in order)
    local pinned = {}
    for _, bufnr in ipairs(pin.get_pinned_buffers()) do
        if utils.is_valid_buffer(bufnr) then
            local name = vim.api.nvim_buf_get_name(bufnr)
            table.insert(pinned, {
                bufnr = bufnr,
                name = name ~= "" and name or "[No Name]",
                pinned = true,
            })
        end
    end
    -- Get unpinned buffers
    local unpinned = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if utils.is_valid_buffer(bufnr) and not pin.is_pinned(bufnr) then
            local name = vim.api.nvim_buf_get_name(bufnr)
            table.insert(unpinned, {
                bufnr = bufnr,
                name = name ~= "" and name or "[No Name]",
                pinned = false,
            })
        end
    end
    -- Concatenate pinned + unpinned
    for _, buf in ipairs(pinned) do table.insert(buffers, buf) end
    for _, buf in ipairs(unpinned) do table.insert(buffers, buf) end

    local function delete_and_refresh(bufnr, force, prompt_bufnr)
        vim.schedule(function()
            -- Close picker before deleting to avoid conflicts
            if prompt_bufnr then
                actions.close(prompt_bufnr)
            end

            -- Perform deletion
            pcall(vim.api.nvim_buf_delete, bufnr, { force = force })

            -- Reopen picker with updated buffer list
            vim.defer_fn(function()
                M.open(opts)
            end, 50) -- Small delay to clean state
        end)
    end

    local function confirm_delete(force)
        return function(prompt_bufnr)
            local selection = action_state.get_selected_entry()
            if selection then
                vim.ui.input({
                    prompt = string.format("%s buffer? (y/n): ", force and "Force delete" or "Delete"),
                }, function(input)
                    if input and input:lower() == "y" then
                        delete_and_refresh(selection.bufnr, force, prompt_bufnr)
                    end
                end)
            end
        end
    end

    pickers
        .new(
            themes.get_dropdown({
                layout_strategy = "horizontal",
                layout_config = {
                    horizontal = {
                        width = opts.width or config.window.width,
                        height = opts.height or config.window.height,
                        preview_width = opts.preview_width or config.window.preview_width,
                        prompt_position = "top",
                        mirror = true,
                    },
                },
                borderchars = {
                    prompt = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
                    results = { "─", "│", "─", "│", "├", "┤", "┘", "└" },
                    preview = { "─", "│", "─", "│", "┌", "┐", "┘", "└" },
                },
                prompt_title = " Buffers ",
            }),
            {
                finder = finders.new_table({
                    results = buffers,
                    entry_maker = function(entry)
                        return M.create_buffer_entry(entry)
                    end,
                }),
                sorter = require("telescope.config").values.generic_sorter({}),
                attach_mappings = function(prompt_bufnr, map)
                    -- Open buffer
                    actions.select_default:replace(function()
                        local selection = action_state.get_selected_entry()
                        actions.close(prompt_bufnr)
                        if selection then
                            vim.api.nvim_set_current_buf(selection.bufnr)
                        end
                    end)

                    -- Delete buffer mappings
                    map("i", "<C-d>", confirm_delete(false))
                    map("i", "<C-D>", confirm_delete(true))
                    map("n", "dd", confirm_delete(false))
                    map("n", "dD", confirm_delete(true))

                    -- Pin/unpin buffer
                    map("n", "p", function()
                        local selection = action_state.get_selected_entry()
                        if selection then
                            pin.toggle_pin(selection.bufnr)
                            actions.close(prompt_bufnr)
                            vim.defer_fn(function() M.open(opts) end, 50)
                        end
                    end)
                    -- Move pinned buffer up
                    map("n", "K", function()
                        local selection = action_state.get_selected_entry()
                        if selection and pin.is_pinned(selection.bufnr) then
                            local pins = pin.get_pinned_buffers()
                            for i, v in ipairs(pins) do
                                if v == selection.bufnr and i > 1 then
                                    pin.move_pinned_buffer(selection.bufnr, i-1)
                                    break
                                end
                            end
                            actions.close(prompt_bufnr)
                            vim.defer_fn(function() M.open(opts) end, 50)
                        end
                    end)
                    -- Move pinned buffer down
                    map("n", "J", function()
                        local selection = action_state.get_selected_entry()
                        if selection and pin.is_pinned(selection.bufnr) then
                            local pins = pin.get_pinned_buffers()
                            for i, v in ipairs(pins) do
                                if v == selection.bufnr and i < #pins then
                                    pin.move_pinned_buffer(selection.bufnr, i+1)
                                    break
                                end
                            end
                            actions.close(prompt_bufnr)
                            vim.defer_fn(function() M.open(opts) end, 50)
                        end
                    end)

                    -- Yank session (copy all buffers)
                    map("n", "Y", function()
                        require("buffer-manager.session").yank_session()
                    end)
                    -- Paste session (restore yanked buffers)
                    map("n", "P", function()
                        require("buffer-manager.session").paste_session()
                        actions.close(prompt_bufnr)
                    end)

                    return true
                end,
            }
        )
        :find()
end

return M

