local M = {}

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
    current_icon = "",
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
    session_dir = vim.fn.stdpath("data") .. "/buffer-manager-sessions",
    session_file = "session.json",
    indicator_icon = "󱡅",
  }
}

function M.setup(opts)
  opts = opts or {}
  M.options = vim.tbl_deep_extend("force", M.options, opts)
  
  if M.options.sessions.enabled then
    vim.fn.mkdir(M.options.sessions.session_dir, "p")
  end

  require("buffer-manager.highlights").setup()
end

return M