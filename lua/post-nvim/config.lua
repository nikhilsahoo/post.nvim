local M = {}

local defaults = {
  session_dir = vim.fn.stdpath("data") .. "/post-nvim",
  session_ttl_days = 30,
  curl = {
    proxy = nil,
    insecure = false,
    connect_timeout = 30,
    max_time = 60,
  },
  ui = {
    response_split = "vertical",
    response_size = 60,
  },
  environments_dir = vim.fn.stdpath("config") .. "/post-nvim-envs",
  http_filetype = "http",
}

M.config = {}

function M.setup(opts)
  M.config = vim.tbl_deep_extend("keep", opts or {}, defaults)
end

function M.get()
  return M.config
end

return M
