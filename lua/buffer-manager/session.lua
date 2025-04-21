local M = {}
local config = require("buffer-manager.config").options
local utils = require("buffer-manager.utils")

-- In-memory clipboard for yanked session
M.session_clipboard = nil

-- Cross-platform path handling
function M.get_session_path()
    local cwd = vim.fn.getcwd():gsub("[^%w%-_]", "_")
    -- Build the session path using the OS separator and normalize
    local sep = package.config:sub(1,1)
    local session_dir = config.sessions.session_dir
    if session_dir:sub(-1) ~= sep then
        session_dir = session_dir .. sep
    end
    local session_path = session_dir .. cwd .. "_" .. config.sessions.session_file
    -- Normalize to forward slashes for Neovim and Windows compatibility
    return utils.normalize_path(vim.fn.fnamemodify(session_path, ":p"))
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
    local session_file_path = M.get_session_path()
    local session_dir = vim.fn.fnamemodify(session_file_path, ":h")
    vim.fn.mkdir(session_dir, "p")

    -- Open the session file with normalized path
    local session_file = io.open(session_file_path, "w")
    if session_file then
        session_file:write(vim.json.encode(buffers))
        session_file:close()
    else
        vim.notify("Failed to save session to: " .. session_file_path, vim.log.levels.ERROR)
    end
end

-- Yank the current session to the clipboard
function M.yank_session()
    local buffers = {}
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        local name = vim.api.nvim_buf_get_name(bufnr)
        if name ~= "" and vim.fn.filereadable(name) == 1 then
            local line = vim.api.nvim_buf_get_mark(bufnr, '"')[1]
            local max_lines = vim.api.nvim_buf_line_count(bufnr)
            if line > max_lines then
                line = max_lines
            end
            table.insert(buffers, {
                path = name,
                line = line,
            })
        end
    end
    if #buffers > 0 then
        M.session_clipboard = vim.deepcopy(buffers)
        vim.notify("Session yanked!", vim.log.levels.INFO)
    else
        vim.notify("No buffers to yank.", vim.log.levels.WARN)
    end
end

-- Paste (restore) the yanked session
function M.paste_session()
    if not M.session_clipboard or #M.session_clipboard == 0 then
        vim.notify("No yanked session to paste.", vim.log.levels.WARN)
        return
    end
    -- Optionally: wipe all listed buffers before restoring
    for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, "buflisted") then
            pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
        end
    end
    -- Restore yanked buffers
    for _, buf in ipairs(M.session_clipboard) do
        if vim.fn.filereadable(buf.path) == 1 then
            pcall(function()
                vim.cmd.edit(vim.fn.fnameescape(buf.path))
                local bufnr = vim.api.nvim_get_current_buf()
                local max_lines = vim.api.nvim_buf_line_count(bufnr)
                if buf.line > 0 and buf.line <= max_lines then
                    vim.api.nvim_win_set_cursor(0, { buf.line, 0 })
                else
                    vim.api.nvim_win_set_cursor(0, { 1, 0 })
                end
            end)
        end
    end
    vim.notify("Session pasted!", vim.log.levels.INFO)
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

-- User commands for yank/paste session
dofile = dofile or loadfile -- Lua 5.1 compatibility
if vim and vim.api then
    vim.api.nvim_create_user_command("BufferManagerYankSession", function()
        require("buffer-manager.session").yank_session()
    end, { desc = "Yank (copy) current buffer session" })
    vim.api.nvim_create_user_command("BufferManagerPasteSession", function()
        require("buffer-manager.session").paste_session()
    end, { desc = "Paste (restore) yanked buffer session" })
end

return M
