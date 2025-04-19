local M = {}

function M.setup()
  vim.api.nvim_set_hl(0, "BufferManagerNormal", { fg = "#abb2bf", bg = "#1e222a" })
  vim.api.nvim_set_hl(0, "BufferManagerBorder", { fg = "#3e4452", bg = "#1e222a" })
  vim.api.nvim_set_hl(0, "BufferManagerTitle", { fg = "#e06c75", bg = "#1e222a", bold = true })
  vim.api.nvim_set_hl(0, "BufferManagerCurrent", { fg = "#e5c07b", bg = "#1e222a", bold = true })
  vim.api.nvim_set_hl(0, "BufferManagerModified", { fg = "#d19a66", bg = "#1e222a" })
  vim.api.nvim_set_hl(0, "BufferManagerDirectory", { fg = "#7daea3", bg = "#1e222a" })
  vim.api.nvim_set_hl(0, "BufferManagerNumber", { fg = "#56b6c2", bg = "#1e222a" })
  vim.api.nvim_set_hl(0, "BufferManagerSession", { fg = "#98c379", bg = "#1e222a", bold = true })
end

return M