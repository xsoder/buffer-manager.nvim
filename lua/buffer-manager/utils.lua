local M = {}
local api = vim.api
local fn = vim.fn
local config = require("buffer-manager.config").options

function M.is_valid_buffer(bufnr)
    return api.nvim_buf_is_valid(bufnr)
        and api.nvim_buf_is_loaded(bufnr)
        and api.nvim_buf_get_option(bufnr, "buflisted")
end

function M.get_icon(bufnr)
    if not config.icons or not config.use_devicons then
        return ""
    end

    local ok, devicons = pcall(require, "nvim-web-devicons")
    if not ok then
        return ""
    end

    local name = api.nvim_buf_get_name(bufnr)
    local filename = fn.fnamemodify(name, ":t")
    local extension = fn.fnamemodify(filename, ":e")
    local icon, _ = devicons.get_icon(filename, extension, { default = true })

    return icon and (icon .. " ") or ""
end

-- Cross-platform path formatting
function M.format_path(path)
    if path == "" then
        return "[No Name]"
    end

    local style = config.style.path_style
    if style == "filename" then
        return fn.fnamemodify(path, ":t")
    elseif style == "relative" then
        -- Handle Windows paths correctly by using fnamemodify
        return fn.fnamemodify(path, ":~:.")
    elseif style == "absolute" then
        -- Normalize path for display
        return fn.fnamemodify(path, ":p")
    elseif style == "shorten" then
        -- Cross-platform path shortening
        if config.platform.is_windows then
            -- Windows-specific path shortening
            local parts = vim.split(path:gsub("\\", "/"), "/")
            if #parts <= 3 then
                return path
            end
            return string.format("%s/…/%s", parts[1], parts[#parts])
        else
            -- Unix-style path shortening
            local parts = vim.split(path, "/")
            if #parts <= 3 then
                return path
            end
            return string.format("%s/…/%s", parts[1], parts[#parts])
        end
    end
    return path
end

-- Cross-platform path normalization
function M.normalize_path(path)
    -- Convert backslashes to forward slashes on Windows
    if config.platform.is_windows then
        return path:gsub("\\", "/")
    end
    return path
end

return M

