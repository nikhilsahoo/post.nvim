local config = require("post-nvim.config")

local M = {}

function M.create_scratch_buf(name)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_name(buf, name)
  vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
  vim.api.nvim_buf_set_option(buf, "bufhidden", "wipe")
  vim.api.nvim_buf_set_option(buf, "swapfile", false)
  return buf
end

function M.open_in_split(buf, direction, size)
  local c = config.get().ui
  local dir = direction or c.response_split
  local sz = size or c.response_size

  if dir == "horizontal" then
    vim.cmd("split")
  else
    vim.cmd("vsplit")
  end

  vim.api.nvim_win_set_buf(0, buf)
  vim.api.nvim_win_set_width(0, sz)
end

function M.set_lines(buf, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function M.set_filetype(buf, ft)
  vim.api.nvim_buf_set_option(buf, "filetype", ft)
end

function M.append_line(buf, line)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  table.insert(lines, line)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function M.clear(buf)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })
end

return M
