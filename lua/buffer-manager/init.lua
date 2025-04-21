local M = {}

function M.setup(opts)
    -- Detect platform first
    opts = opts or {}
    if opts.platform == nil then
        opts.platform = {
            is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1,
        }
    end

    -- Setup the rest of the plugin
    require("buffer-manager.config").setup(opts)

    -- Load session after setup (if enabled and auto_load_session is true)
    local conf = require("buffer-manager.config").options
    if conf.sessions.auto_load_session ~= false then
        pcall(function()
            require("buffer-manager.session").load_session()
        end)
    end

    -- Commands
    vim.api.nvim_create_user_command("BufferManager", function()
        require("buffer-manager.ui").open()
    end, {})

    vim.api.nvim_create_user_command("BufferManagerSaveSession", function()
        local success, err = pcall(function()
            require("buffer-manager.session").save_session()
        end)

        if success then
            vim.notify("Buffer session saved", vim.log.levels.INFO)
        else
            vim.notify("Failed to save session: " .. tostring(err), vim.log.levels.ERROR)
        end
    end, {})

    vim.api.nvim_create_user_command("BufferManagerLoadSession", function()
        local success, err = pcall(function()
            require("buffer-manager.session").load_session()
        end)

        if success then
            vim.notify("Buffer session loaded", vim.log.levels.INFO)
        else
            vim.notify("Failed to load session: " .. tostring(err), vim.log.levels.ERROR)
        end
    end, {})

    -- Keymaps
    local conf = require("buffer-manager.config").options
    if conf.default_mappings then
        vim.keymap.set("n", conf.mappings.open, M.open, { desc = "Open buffer manager" })
        vim.keymap.set("n", conf.mappings.delete, function()
            M.delete_buffer(false)
        end, { desc = "Delete current buffer" })
        vim.keymap.set("n", conf.mappings.delete_force, function()
            M.delete_buffer(true)
        end, { desc = "Force delete current buffer" })
        vim.keymap.set("n", "<leader>bss", "<cmd>BufferManagerSaveSession<cr>", { desc = "Save buffer session" })
        vim.keymap.set("n", "<leader>bsl", "<cmd>BufferManagerLoadSession<cr>", { desc = "Load buffer session" })
    end
end

M.open = function(opts)
    require("buffer-manager.ui").open(opts)
end

M.delete_buffer = function(force, bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    vim.api.nvim_buf_delete(bufnr, { force = force })
end

return M

