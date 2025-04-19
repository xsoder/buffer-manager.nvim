local M = {}
local config = require("buffer-manager.config").options

-- Cross-platform path handling
function M.get_session_path()
    local cwd = vim.fn.getcwd():gsub("[^%w%-_]", "_")
    -- Use vim.fn.fnamemodify to normalize path (works on all platforms)
    return vim.fn.fnamemodify(config.sessions.session_dir .. "/" .. cwd .. "_" .. config.sessions.session_file, ":p")
end

function M.save_session()
    if not config.sessions.enabled then
        return
    end

    local buffers = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name ~= "" and vim.fn.filereadable(name) == 1 then
            local line = vim.api.nvim_buf_get_mark(bufnr, '"')[1]
            local max_lines = vim.api.nvim_buf_line_count(bufnr)
            -- Ensure cursor position is valid
            if line > max_lines then
                line = max_lines
            end
            table.insert(buffers, {
                path = name,
                line = line,
            })
        end
    end

    -- Make sure parent directory exists
    vim.fn.mkdir(vim.fn.fnamemodify(M.get_session_path(), ":h"), "p")

    local session_file_path = M.get_session_path()
    local session_file = io.open(session_file_path, "w")
    if session_file then
        session_file:write(vim.json.encode(buffers))
        session_file:close()
    else
        vim.notify("Failed to save session to: " .. session_file_path, vim.log.levels.ERROR)
    end
end

function M.load_session()
    if not config.sessions.enabled then
        return
    end

    local session_file_path = M.get_session_path()
    local session_file = io.open(session_file_path, "r")
    if not session_file then
        -- Don't show error, silently fail if no session file exists
        return
    end

    local content = session_file:read("*a")
    session_file:close()

    if content == "" then
        return
    end

    local success, decoded = pcall(vim.json.decode, content)
    if not success or type(decoded) ~= "table" then
        vim.notify("Failed to parse session file: " .. session_file_path, vim.log.levels.WARN)
        return
    end

    for _, buf in ipairs(decoded) do
        if vim.fn.filereadable(buf.path) == 1 then
            -- Use pcall for error handling
            pcall(function()
                -- Use vim.cmd.edit for better cross-platform behavior
                vim.cmd.edit(vim.fn.fnameescape(buf.path))
                local bufnr = vim.api.nvim_get_current_buf()
                local max_lines = vim.api.nvim_buf_line_count(bufnr)
                -- Validate line position before setting
                if buf.line > 0 and buf.line <= max_lines then
                    vim.api.nvim_win_set_cursor(0, { buf.line, 0 })
                else
                    vim.api.nvim_win_set_cursor(0, { 1, 0 }) -- Fallback to line 1
                end
            end)
        end
    end
end

function M.is_in_session(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)
    if path == "" then
        return false
    end

    local session_file = io.open(M.get_session_path(), "r")
    if not session_file then
        return false
    end

    local content = session_file:read("*a")
    session_file:close()

    if content == "" then
        return false
    end

    local success, decoded = pcall(vim.json.decode, content)
    if not success then
        return false
    end

    for _, buf in ipairs(decoded or {}) do
        if buf.path == path then
            return true
        end
    end
    return false
end

-- Auto-save on exit
vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
        if config.sessions.auto_save then
            M.save_session()
        end
    end,
})

return M
