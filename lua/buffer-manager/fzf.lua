local M = {}
local api = vim.api
local fn = vim.fn
local config = require("buffer-manager.config")
local previewers = require("buffer-manager.previewers")
local utils = require("buffer-manager.utils")

function M.search()
    if not config.options.fzf.enabled then
        vim.notify("FZF is disabled in configuration", vim.log.levels.WARN)
        return
    end

    local ok, fzf = pcall(require, "fzf-lua")
    if not ok then
        vim.notify("FZF-Lua not installed", vim.log.levels.ERROR)
        return
    end

    local buffers = {}
    for _, bufnr in ipairs(api.nvim_list_bufs()) do
        if utils.is_valid_buffer(bufnr) then
            local name = api.nvim_buf_get_name(bufnr)
            if name ~= "" then
                local modified = api.nvim_buf_get_option(bufnr, "modified") and "[+] " or ""
                local current = api.nvim_get_current_buf() == bufnr and "[*] " or ""
                local icon = utils.get_icon(bufnr)
                table.insert(buffers, {
                    bufnr = bufnr,
                    display = string.format("%s%s%s%s (%d)", 
                        icon, modified, current, 
                        fn.fnamemodify(name, ":t"), 
                        bufnr
                    ),
                    name = name,
                })
            end
        end
    end

    fzf.fzf_exec(
        vim.tbl_map(function(buf) return buf.display end, buffers),
        {
            prompt = config.options.fzf.prompt,
            previewer = previewers.create_fzf_previewer(),
            preview_opts = config.options.fzf.preview_window,
            winopts = {
                height = math.floor(vim.o.lines * config.options.fzf.window_height),
                width = math.floor(vim.o.columns * config.options.fzf.window_width),
                row = math.floor((vim.o.lines - (vim.o.lines * config.options.fzf.window_height)) / 2),
            },
            actions = {
                ["default"] = function(selected)
                    if selected and selected[1] then
                        for _, buf in ipairs(buffers) do
                            if buf.display == selected[1] then
                                api.nvim_set_current_buf(buf.bufnr)
                                break
                            end
                        end
                    end
                end,
            },
        }
    )
end

return M