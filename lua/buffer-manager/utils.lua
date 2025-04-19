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
  if not config.icons or not config.use_devicons then return "" end
  
  local ok, devicons = pcall(require, "nvim-web-devicons")
  if not ok then return "" end
  
  local name = api.nvim_buf_get_name(bufnr)
  local filename = fn.fnamemodify(name, ":t")
  local extension = fn.fnamemodify(filename, ":e")
  local icon, _ = devicons.get_icon(filename, extension, { default = true })
  
  return icon and (icon .. " ") or ""
end

function M.format_path(path)
  if path == "" then return "[No Name]" end
  
  local style = config.style.path_style
  if style == "filename" then
    return fn.fnamemodify(path, ":t")
  elseif style == "relative" then
    return fn.fnamemodify(path, ":~:.")
  elseif style == "absolute" then
    return path
  elseif style == "shorten" then
    local parts = vim.split(path, "/")
    if #parts <= 3 then return path end
    return string.format("%s/%s/%s", parts[1], "…", parts[#parts])
  end
  return path
end

return M