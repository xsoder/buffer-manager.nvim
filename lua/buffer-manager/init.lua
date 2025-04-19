local M = {}

function M.setup(opts)
  require("buffer-manager.config").setup(opts)
  require("buffer-manager.session").load_session()
  
  -- Commands
  vim.api.nvim_create_user_command("BufferManager", function()
    require("buffer-manager.ui").open()
  end, {})

  vim.api.nvim_create_user_command("BufferManagerSaveSession", function()
    require("buffer-manager.session").save_session()
    vim.notify("Buffer session saved", vim.log.levels.INFO)
  end, {})

  vim.api.nvim_create_user_command("BufferManagerLoadSession", function()
    require("buffer-manager.session").load_session()
    vim.notify("Buffer session loaded", vim.log.levels.INFO)
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