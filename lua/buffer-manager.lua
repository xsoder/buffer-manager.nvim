local M = {}

function M.setup()
  if vim.g.loaded_buffer_manager == 1 then
    return
  end
  vim.g.loaded_buffer_manager = 1

  -- Set default leader if not set
  if vim.g.mapleader == nil then
    vim.g.mapleader = " "
  end

  -- Add more plugin initialization logic here
end

return M
