local M = {}

M.pinned = {}

-- Helper: Remove a value from a table
local function remove_value(tbl, val)
    for i, v in ipairs(tbl) do
        if v == val then
            table.remove(tbl, i)
            return
        end
    end
end

-- Pin a buffer (adds to end of pinned list)
function M.pin_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if not M.is_pinned(bufnr) then
        table.insert(M.pinned, bufnr)
    end
end

-- Unpin a buffer
function M.unpin_buffer(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    remove_value(M.pinned, bufnr)
end

-- Toggle pin state
function M.toggle_pin(bufnr)
    bufnr = bufnr or vim.api.nvim_get_current_buf()
    if M.is_pinned(bufnr) then
        M.unpin_buffer(bufnr)
    else
        M.pin_buffer(bufnr)
    end
end

-- Move a pinned buffer to a new index (1-based)
function M.move_pinned_buffer(bufnr, new_index)
    for i, v in ipairs(M.pinned) do
        if v == bufnr then
            table.remove(M.pinned, i)
            table.insert(M.pinned, math.max(1, math.min(new_index, #M.pinned+1)), bufnr)
            break
        end
    end
end

-- Get all pinned buffers (in order)
function M.get_pinned_buffers()
    -- Remove invalid buffers
    local valid = {}
    for _, bufnr in ipairs(M.pinned) do
        if vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_is_loaded(bufnr) then
            table.insert(valid, bufnr)
        end
    end
    M.pinned = valid
    return vim.deepcopy(M.pinned)
end

-- Is a buffer pinned?
function M.is_pinned(bufnr)
    for _, v in ipairs(M.pinned) do
        if v == bufnr then return true end
    end
    return false
end

-- Jump to pinned buffer by 1-based index
function M.jump_to_pin(index)
    local pins = M.get_pinned_buffers()
    local bufnr = pins[index]
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
        vim.api.nvim_set_current_buf(bufnr)
    else
        vim.notify("No pinned buffer at index " .. tostring(index), vim.log.levels.WARN)
    end
end

-- Setup mappings: <space>b1, <space>b2, <space>b3, ...
for i = 1, 9 do
    vim.keymap.set("n", string.format("<space>b%d", i), function()
        require("buffer-manager.pin").jump_to_pin(i)
    end, { desc = string.format("Go to pinned buffer #%d", i) })
end

return M
