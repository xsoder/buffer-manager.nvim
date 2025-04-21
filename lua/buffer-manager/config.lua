local M = {}

-- Function to get cross-platform data directory
local function get_data_dir()
    local data_dir = vim.fn.stdpath("data")
    -- Always use / as separator for Neovim paths
    if data_dir:sub(-1) ~= "/" then
        data_dir = data_dir .. "/"
    end
    -- Convert any backslashes to forward slashes (for Windows)
    data_dir = data_dir:gsub("\\", "/")
    -- Remove duplicate slashes except after drive letter (C:/)
    data_dir = data_dir:gsub("([^:])/+", "%1/")
    return data_dir
end

M.options = {
    icons = true,
    use_devicons = true,
    default_mappings = true,
    window = {
        width = 0.8,
        height = 0.7,
        border = "rounded",
        preview_width = 0.5,
    },
    style = {
        numbers = "ordinal",
        modified_icon = "●",
        current_icon = "",
        path_style = "shorten",
    },
    mappings = {
        open = "<leader>bb",
        vertical = "<leader>bv",
        horizontal = "<leader>bs",
        delete = "<leader>bd",
        delete_force = "<leader>bD",
    },
    sessions = {
        enabled = true,
        auto_save = true,
        auto_load_session = false, -- If false, disables auto-loading session on startup (default: false)
        session_dir = get_data_dir() .. "buffer-manager-sessions",
        session_file = "session.json",
        indicator_icon = "󱡅",
    },
    -- Add cross-platform specific settings
    platform = {
        is_windows = vim.fn.has("win32") == 1 or vim.fn.has("win64") == 1,
    },
}

function M.setup(opts)
    opts = opts or {}
    M.options = vim.tbl_deep_extend("force", M.options, opts)

    -- Create session directory on all platforms
    if M.options.sessions.enabled then
        -- Normalize path and ensure parent directories are created
        local session_dir = vim.fn.fnamemodify(M.options.sessions.session_dir, ":p")
        vim.fn.mkdir(session_dir, "p")
    end

    require("buffer-manager.highlights").setup()
end

return M

